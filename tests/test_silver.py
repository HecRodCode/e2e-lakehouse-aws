import datetime as dt

import pytest
from pyspark.sql import SparkSession

from spark.jobs.silver_transform import clean_events, split_quarantine

COLS = ["event_time", "event_type", "product_id", "category_id", "category_code",
        "brand", "price", "user_id", "user_session"]
TYPES = ["string", "string", "bigint", "bigint", "string", "string", "double", "bigint", "string"]


@pytest.fixture(scope="module")
def spark():
    s = (SparkSession.builder.master("local[1]")
         .config("spark.sql.session.timeZone", "UTC")
         .config("spark.ui.enabled", "false").getOrCreate())
    yield s
    s.stop()


def mk(spark, rows):
    schema = ",".join(f"{c} {t}" for c, t in zip(COLS, TYPES))
    return spark.createDataFrame(rows, schema=schema)


def test_quarantine_rules(spark):
    t = "2019-10-01 00:00:00 UTC"
    df = mk(spark, [
        (t, "purchase", 1, 1, "a", "b", 0.0, 1, "s1"),
        (t, "purchase", 1, 1, "a", "b", None, 1, "s1"),
        (t, "view", 1, 1, "a", "b", 0.0, 1, "s1"),
        (t, "view", 1, 1, "a", "b", 5.0, 1, None),
        (t, "purchase", 1, 1, "a", "b", 0.0, 1, None),
        (t, "purchase", 1, 1, "a", "b", 9.9, 1, "s1"),
    ])
    ok, rej = split_quarantine(df)
    assert ok.count() == 2
    reasons = sorted(r.reject_reason for r in rej.collect())
    assert reasons == ["purchase_sin_precio_valido"] * 2 + ["user_session_nulo"] * 2


def test_clean_events(spark):
    t = "2019-10-01 10:20:30 UTC"
    df = mk(spark, [
        (t, "view", 1, 1, None, "nike", 10.0, 7, "s"),
        (t, "view", 1, 1, None, "nike", 10.0, 7, "s"),
        (t, "view", 1, 1, "x", None, 10.0, 7, "s"),
        (t, "view", 1, 1, None, "x", 10.0, 7, "s"),
        (t, "view", 2, 1, "c", "b", 0.0, 7, "s"),
    ])
    out = clean_events(df)
    rows = out.collect()
    assert len(rows) == 4
    assert len({r.event_hash for r in rows}) == 4
    assert dict(out.dtypes)["event_time"] == "timestamp_ntz"
    r = [x for x in rows if x.product_id == 1 and x.brand == "nike"][0]
    assert r.event_time == dt.datetime(2019, 10, 1, 10, 20, 30)
    assert r.category_code == "unknown"
    assert r.price_is_valid is True and r.price_imputed is False
    z = [x for x in rows if x.product_id == 2][0]
    assert z.price_is_valid is False
    assert all(x.brand is not None and x.category_code is not None for x in rows)

def test_impute_prices(spark):
    from spark.jobs.silver_transform import impute_prices

    def ev(pid, sec, price, tag):
        return (f"2019-10-01 10:00:{sec:02d} UTC", "view", pid, 1, "c", "b", price, 7, tag)

    rows = [
        ev(1, 1, 10.0, "p1a"), ev(1, 2, 0.0, "p1b"),
        ev(2, 1, 0.0, "p2a"), ev(2, 2, 20.0, "p2b"),
        ev(3, 1, 0.0, "p3a"), ev(3, 2, 0.0, "p3b"),
        ev(4, 1, 5.0, "p4a"), ev(4, 2, 6.0, "p4b"),
        ev(5, 1, 10.0, "p5a"), ev(5, 2, 0.0, "p5b"), ev(5, 3, 30.0, "p5c"),
    ]
    out = {r.user_session: r for r in impute_prices(clean_events(mk(spark, rows))).collect()}
    assert len(out) == 11
    assert out["p1b"].price == 10.0 and out["p1b"].price_imputed and out["p1b"].price_is_valid
    assert out["p2a"].price == 20.0 and out["p2a"].price_imputed
    assert out["p3a"].price is None and not out["p3a"].price_is_valid and not out["p3a"].price_imputed
    assert out["p4a"].price == 5.0 and not out["p4a"].price_imputed and out["p4a"].price_is_valid
    assert out["p5b"].price == 10.0
    assert out["p5c"].price == 30.0 and not out["p5c"].price_imputed