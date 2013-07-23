
--create database test
CREATE DATABASE IF NOT EXISTS tmp;
use tmp;


--DDL Operations
--创建表
CREATE TABLE pokes (foo INT, bar STRING); 
--创建表并创建索引字段ds
CREATE TABLE invites (foo INT, bar STRING) PARTITIONED BY (ds STRING); 
--显示所有表
SHOW TABLES;
--按正条件（正则表达式）显示表
SHOW TABLES '.*s';
--表添加一列 
ALTER TABLE pokes ADD COLUMNS (new_col INT);
--添加一列并增加列字段注释
ALTER TABLE invites ADD COLUMNS (new_col2 INT COMMENT 'a comment');

CREATE TABLE torename(foo INT, bar STRING);
--更改表名
ALTER TABLE torename RENAME TO 3koobecaf;
--删除表
DROP TABLE 3koobecaf;


--元数据存储
--将文件中的数据加载到表中
LOAD DATA LOCAL INPATH './examples/files/kv1.txt' OVERWRITE INTO TABLE pokes; 
--加载本地数据，同时给定分区信息
LOAD DATA LOCAL INPATH './examples/files/kv2.txt' OVERWRITE INTO TABLE invites PARTITION (ds='2013-01-25');
--加载DFS数据 ，同时给定分区信息
dfs -put examples/files/kv2.txt /user/${env:USER}/;
LOAD DATA INPATH '/user/${env:USER}/kv2.txt' OVERWRITE INTO TABLE invites PARTITION (ds='2013-01-24');

--SQL 操作
--按先件查询
SET hivevar:DATE='2013-01-25';
SELECT a.foo FROM invites a WHERE a.ds=${hivevar:DATE};
--将查询数据输出至目录
INSERT OVERWRITE DIRECTORY '/tmp/hdfs_out' SELECT a.* FROM invites a WHERE a.ds=${hivevar:DATE};
dfs -rmr /tmp/hdfs_out ;
--将查询结果输出至本地目录
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/local_out' SELECT a.* FROM pokes a;
!rm -rf /tmp/local_out;

--选择所有列到本地目录
CREATE TABLE result (foo INT, bar STRING, new_col2 INT, ds STRING);
INSERT OVERWRITE TABLE result SELECT a.* FROM invites a;
INSERT OVERWRITE TABLE result SELECT a.* FROM invites a WHERE a.foo < 100; 
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/reg_3' SELECT e.* FROM result e;
INSERT OVERWRITE DIRECTORY '/tmp/reg_4' select e.foo, e.bar FROM result e;
INSERT OVERWRITE DIRECTORY '/tmp/reg_5' SELECT COUNT(1) FROM invites a WHERE a.ds=${hivevar:DATE};
INSERT OVERWRITE DIRECTORY '/tmp/reg_5' SELECT a.foo, a.bar FROM invites a;
dfs -rmr /tmp/reg*;
!rm -rf /tmp/reg_3;
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/sum' SELECT SUM(a.foo) FROM invites a;
!rm -rf /tmp/sum;

--将一个表的统计结果插入另一个表中
CREATE TABLE result2 (bar STRING, count INT);
FROM invites a INSERT OVERWRITE TABLE result2 SELECT a.bar, count(1) WHERE a.foo > 0 GROUP BY a.bar;
INSERT OVERWRITE TABLE result2 SELECT a.bar, count(1) FROM invites a WHERE a.foo > 0 GROUP BY a.bar;

--JOIN
CREATE TABLE jointest (bar1 STRING,foo1 INT, bar2 STRING, foo2 INT);
FROM pokes t1 JOIN invites t2 ON (t1.bar = t2.bar) INSERT OVERWRITE TABLE jointest SELECT t1.bar, t1.foo, t2.bar, t2.foo;

DROP TABLE pokes;
DROP TABLE invites;
DROP TABLE result;
DROP TABLE result2;
DROP TABLE jointest;
