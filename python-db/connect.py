import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy import text
from sqlalchemy.orm import DeclarativeBase, Session
load_dotenv()


pip install databricks-sql-connector

access_token    = os.getenv("DATABRICKS_TOKEN")
host            = os.getenv("DATABRICKS_HOST")
http_path       =  "/sql/1.0/warehouses/300bd24ba12adf8e"
catalog         = "workshops"
schema          = "samples"

engine = create_engine(
    f"databricks://token:{access_token}@{host}?http_path={http_path}&catalog={catalog}&schema={schema}",
    echo=True,
)

with engine.connect() as con:
    rs = con.execute(text('SELECT * FROM lendingclub limit 10'))

