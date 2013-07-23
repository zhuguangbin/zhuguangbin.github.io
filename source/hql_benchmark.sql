
--create database test
CREATE DATABASE IF NOT EXISTS tmp;
use tmp;


--DDL Operations
--������
CREATE TABLE pokes (foo INT, bar STRING); 
--���������������ֶ�ds
CREATE TABLE invites (foo INT, bar STRING) PARTITIONED BY (ds STRING); 
--��ʾ���б�
SHOW TABLES;
--����������������ʽ����ʾ��
SHOW TABLES '.*s';
--�����һ�� 
ALTER TABLE pokes ADD COLUMNS (new_col INT);
--���һ�в��������ֶ�ע��
ALTER TABLE invites ADD COLUMNS (new_col2 INT COMMENT 'a comment');

CREATE TABLE torename(foo INT, bar STRING);
--���ı���
ALTER TABLE torename RENAME TO 3koobecaf;
--ɾ����
DROP TABLE 3koobecaf;


--Ԫ���ݴ洢
--���ļ��е����ݼ��ص�����
LOAD DATA LOCAL INPATH './examples/files/kv1.txt' OVERWRITE INTO TABLE pokes; 
--���ر������ݣ�ͬʱ����������Ϣ
LOAD DATA LOCAL INPATH './examples/files/kv2.txt' OVERWRITE INTO TABLE invites PARTITION (ds='2013-01-25');
--����DFS���� ��ͬʱ����������Ϣ
dfs -put examples/files/kv2.txt /user/${env:USER}/;
LOAD DATA INPATH '/user/${env:USER}/kv2.txt' OVERWRITE INTO TABLE invites PARTITION (ds='2013-01-24');

--SQL ����
--���ȼ���ѯ
SET hivevar:DATE='2013-01-25';
SELECT a.foo FROM invites a WHERE a.ds=${hivevar:DATE};
--����ѯ���������Ŀ¼
INSERT OVERWRITE DIRECTORY '/tmp/hdfs_out' SELECT a.* FROM invites a WHERE a.ds=${hivevar:DATE};
dfs -rmr /tmp/hdfs_out ;
--����ѯ������������Ŀ¼
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/local_out' SELECT a.* FROM pokes a;
!rm -rf /tmp/local_out;

--ѡ�������е�����Ŀ¼
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

--��һ�����ͳ�ƽ��������һ������
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
