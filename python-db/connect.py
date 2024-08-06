# pip install sqlalchemy
# pip install databricks-sql-connector
# pip install python-dotenv

import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, Session

load_dotenv()

engine = create_engine(
    f"databricks://token:{os.getenv("DATABRICKS_TOKEN")}" + \
    f"@{os.getenv("DATABRICKS_HOST")}" + \
    "?http_path=/sql/1.0/warehouses/300bd24ba12adf8e" + \
    f"&catalog=workshops&" + \
    f"schema=samples",
    echo=True,
)

df = pd.read_sql_query('SELECT * FROM lendingclub limit 10', engine)
print(df)
