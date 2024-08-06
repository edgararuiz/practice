# pip install sqlalchemy
# pip install databricks-sql-connector
# pip install python-dotenv

import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, Session

load_dotenv()

access_token    = os.getenv("DATABRICKS_TOKEN")
host            = os.getenv("DATABRICKS_HOST")
http_path       =  "/sql/1.0/warehouses/300bd24ba12adf8e"
catalog         = "workshops"
schema          = "samples"

engine = create_engine(
    f"databricks://token:{access_token}@{host}?http_path={http_path}&catalog={catalog}&schema={schema}",
    echo=True,
)
session = Session(engine)
res = session.execute(text('SELECT * FROM lendingclub limit 10'))
df = pd.read_sql_query('SELECT * FROM lendingclub limit 10', engine)
print(df)
