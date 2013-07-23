---
layout: post
title: "Shark vs Hive Benchmark Test"
date: 2013-07-23 13:42
comments: true
categories: 
---

为了测试Shark和Hive的执行效率，今天做了下Benchmark的测试对比，测试性能非常满意，虽然没有达到官方宣称的100倍，但至少10倍的性能提升。

<!--more-->

####测试工具与方法：

  之前写过一个[benchmark sql](/images/benchmark.hql)，利用hive自带的testcase的数据，创建表并进行一些基准HQL的测试；
  测试方法就是分别利用Hive和Shark的CliDriver:
  
    * time hive -f hql_benchmark.sql > hive_test_result 2>&1
    * time shark-witherror -f hql_benchmark.sql > shark_test_result 2>&1	
  
####集群资源情况：

  * Hive/MapReduce集群：
  	* 37 Node, 436 MapSlot & 436 ReduceSlot total, 1 slot per task
  * Shark/Spark集群：
  	* 3 node, 48 core & 48G mem total, 12 core max & 4G mem per node for each client

####测试结果：

  测试结果对比如下：
  
|Hive/Shark  |real time  |user time   |sys time|
|------------|-----------|------------|--------|
|Hive: 	     |*23m2.292s*|0m33.430s   |0m3.014s
|Shark:	     |*1m42.698s*|0m30.694s   |0m3.193s

  详细结果结果请看：
 [hive_test_result](/images/hive_test_result)
 [shark_test_result](/images/shark_test_result)

####测试结果解读：
				
  * SQL 兼容性：shark完全兼容hive的语法，hive能够执行的语法，shark能够无缝的执行，因此迁移成本为零	
  
  * 性能：不言而喻，Shark在集群资源只有三个节点而MR有39的节点下，仍然能够比Hive执行效率高出近13倍	
  	
  * 原因分析：本次测试，数据量并不算大，所以对于MR和Spark而言，读取文件的IO开销几乎无异。造成执行时间差异如此大的原因在于MR与Spark计算框架的开销。
  
  从测试结果看，user time两者的耗时几乎相等，原因是shark和hive在客户端做的事情几乎一致（主要是compile阶段将SQL转化成QueryPlan）。
  而real time主要耗时在等待集群计算结果上，从计算框架的调度角度来看，MR框架的调度很重，通过heatbeat来分配MapSlot和ReduceSlot，而Spark的Actor模型，比较轻量级；从计算模型来看，MR的Map-Shuffle-Reduce绝大部分的开销在于中间结果的persistence上，IO开销很重，而Spark通过RDD transformation和action操作，并且可以充分利用内存，IO的开销比MR要轻的多
  
####测试中遇到的问题：

  在执行join时，偶尔会遇到ArrayIndexOutOfBoundsException的错误，原因是我们的shark采用了Dianping自有的cosmos-hadoop-0.9.0版本（基于apache官方0.9.0版本打过自己的patch），而官方版本有concurrency的问题。在amplab的版本中已经修复过。
  后续将amplab的concurrency的commit梳理，引入到我们的版本来。
  


