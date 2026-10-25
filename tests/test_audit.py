from datetime import datetime
from unittest.mock import MagicMock

import pytest
from pyspark.sql import SparkSession

from spark import audit
from spark.jobs import silver_transform as st


def test_run_row_fits_schema():
    spark = SparkSession.builder.master("local[1]").config("spark.ui.enabled", "false").getOrCreate()
    t0, t1 = datetime(2026, 10, 24, 10, 0, 0), datetime(2026, 10, 24, 10, 34, 1)
    row = audit.run_row("r1", "silver_transform", "success", t0, t1, 10, 8, 2, '{"a": 1}', None)
    out = spark.createDataFrame([row], audit.SCHEMA).collect()[0]
    assert out.duration_seconds == 2041.0 and out.error_message is None
    failed = audit.run_row("r2", "silver_transform", "failed", t0, t1, error_message="boom")
    assert spark.createDataFrame([failed], audit.SCHEMA).collect()[0].rows_read is None


def _patch(monkeypatch, run_silver):
    calls = []
    monkeypatch.setattr(st, "get_spark", lambda name: MagicMock())
    monkeypatch.setattr(st, "ensure_table", lambda spark: None)
    monkeypatch.setattr(st, "run_silver", run_silver)
    monkeypatch.setattr(st, "record_run", lambda spark, **kw: calls.append(kw))
    return calls


def test_main_records_success(monkeypatch):
    calls = _patch(monkeypatch, lambda spark, bid: {"rows_read": 10, "rows_written": 8,
                                                    "rows_rejected": 2, "duplicados_eliminados": 0})
    st.main()
    assert calls[0]["status"] == "success" and calls[0]["rows_written"] == 8
    assert calls[0]["error_message"] is None


def test_main_records_failure_and_reraises(monkeypatch):
    def boom(spark, bid):
        raise ValueError("falló algo")
    calls = _patch(monkeypatch, boom)
    with pytest.raises(ValueError):
        st.main()
    assert calls[0]["status"] == "failed" and "falló algo" in calls[0]["error_message"]