import pandas as pd
from sqlalchemy import create_engine

# 连接字符串(把 YOUR_PASSWORD 改成你的 root 密码)
engine = create_engine(
    'mysql+pymysql://root:123456@localhost:3306/online_retail?charset=utf8mb4'
)

# 读取清洗后的数据
data_sales = pd.read_csv('./data/cleaned_sales.csv', parse_dates=['InvoiceDate'])
data_customer = pd.read_csv('./data/cleaned_customer.csv', parse_dates=['InvoiceDate'])

print(f"sales: {len(data_sales):,} 行")
print(f"customer: {len(data_customer):,} 行")

# 写入 MySQL(100 万行需要 1-2 分钟,耐心等)
print("正在导入 sales 表...")
data_sales.to_sql('sales', engine, if_exists='replace', index=False, chunksize=10000)

print("正在导入 customer 表...")
data_customer.to_sql('customer', engine, if_exists='replace', index=False, chunksize=10000)

print("✓ 导入完成")

