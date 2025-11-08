import os
import urllib.parse
import boto3
import awswrangler as wr  # provided by Lambda layer
import pandas as pd
from io import StringIO

# ==============================================================
# Phase 3A — lightweight schema validation + bad-row routing
# ==============================================================

REQUIRED_COLS = ["id", "name", "email"]
CLEAN_BUCKET = os.environ["CLEAN_BUCKET"]
s3 = boto3.client("s3")


def validate_df(df: pd.DataFrame, bucket: str, key_prefix: str) -> pd.DataFrame:
    """
    Ensures required columns exist; routes invalid rows to clean/error/*.csv.
    key_prefix example: 'WJTest/customers_1762625441'
    """
    missing = [c for c in REQUIRED_COLS if c not in df.columns]
    if missing:
        raise ValueError(f"Missing columns: {missing}")

    # basic row-level quality checks
    good = df.dropna(subset=["id", "email"])
    bad = df.loc[~df.index.isin(good.index)]

    # route bad rows to error prefix if any exist
    if not bad.empty:
        buf = StringIO()
        bad.to_csv(buf, index=False)
        error_key = key_prefix.replace("WJTest", "error") + ".csv"
        s3.put_object(Bucket=bucket, Key=error_key, Body=buf.getvalue())

    return good


# ==============================================================
# Main Lambda handler
# ==============================================================

def handler(event, _ctx):
    """Triggered by S3 ObjectCreated events from the landing zone."""
    rec = event["Records"][0]["s3"]
    bucket_in = rec["bucket"]["name"]
    key_in = urllib.parse.unquote(rec["object"]["key"])
    src_uri = f"s3://{bucket_in}/{key_in}"

    # --- read CSV into DataFrame ---
    df = wr.s3.read_csv(src_uri)

    # --- light normalization ---
    df.columns = [c.strip().lower().replace(" ", "_") for c in df.columns]

    # --- validate + filter bad rows ---
    base_name = os.path.splitext(os.path.basename(key_in))[0]
    df = validate_df(df, CLEAN_BUCKET, f"WJTest/{base_name}")

    # --- write Parquet to clean zone ---
    key_out = key_in.replace("landing/", "clean/").rsplit(".", 1)[0] + ".parquet"
    dst_uri = f"s3://{CLEAN_BUCKET}/{key_out}"
    wr.s3.to_parquet(df=df, path=dst_uri, dataset=False, compression="snappy")

    return {"status": "ok", "in": src_uri, "out": dst_uri, "rows": len(df)}
