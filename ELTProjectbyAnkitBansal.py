#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import kaggle


# In[2]:


get_ipython().system('kaggle datasets download shivamb/netflix-shows -f netflix_titles.csv')


# In[3]:


import zipfile

zip_file = zipfile.ZipFile('netflix_titles.csv.zip')

zip_file.extractall()
zip_file.close()


# In[4]:


import pandas as pd


# In[5]:


df = pd.read_csv('netflix_titles.csv')


# In[6]:


df.head(10)


# In[33]:


df.shape


# In[9]:


#load the data into sql server using replace option
get_ipython().system('pip install sqlalchemy pyodbc')
import sqlalchemy as sal
from sqlalchemy import create_engine,NVARCHAR
engine=sal.create_engine('mssql://LAPTOP-HDFJR04B\SQLEXPRESS/master?driver=ODBC+DRIVER+17+FOR+SQL+SERVER')
dtype={'title':NVARCHAR(length=1000)}
conn=engine.connect()


# In[10]:


df.to_sql('netflix_raw', con=conn , index=False , if_exists='append', dtype=dtype)
conn.close()


# In[12]:


len(df)


# In[36]:


df[df.show_id=='s5023']


# In[18]:


max(df.show_id.str.len())   #we have used str.len() in order to check the length of the string in that column then max to
                            #have the maximum length of the column and str have nothing to do with the datatypes
                            


# In[19]:


max(df.title.str.len())


# In[20]:


max(df.cast.str.len())


# While having count for datatypes, we see that the ‘cast’ column has null values, and whenever we take max or count of a column
#and if it contains null values, it is going to display ‘nan’ as the final output. Therefore, we need to use ‘dropna()’ in order 
#to drop those null values. 


# In[22]:


max(df.cast.dropna().str.len())


# In[11]:


## checking null values

df.isna()


# In[12]:


# we will sum the values against all columns in df grouping true (1) and false (0) and providing columns with null values with count

df.isna().sum()


# In[ ]:




