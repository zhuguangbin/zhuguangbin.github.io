---
layout: post
title: "Spark核心思想篇"
date: 2013-07-16 10:58
comments: true
categories: 
---


Spark的核心思想是RDD，以及对RDD的操作（transformation/action）。本篇简单介绍这些基本概念，以有利于理解Spark的原理。

###(一) RDD(resilient distributed dataset)

1. ** RDD的基本概念**  
  RDD是AMPLAB提出的一种概念，类似与分布式内存，但又不完全一致（关于RDD与分布式内存的区别可参考[paper](http://www.cs.berkeley.edu/~matei/papers/2012/nsdi_spark.pdf)）。    
  RDD在Spark的实现中，其实是一个只读的Scala集合对象，它能够进行分区（partition）以便于分布在各个Worker节点上，同时提供了lineage机制（其实就是维护了当前RDD的父RDD reference以及生成RDD的Operation）保证在Worker节点宕机时自动重建。    
  RDD是lazy的，不必每次都物化出来，因为它维持了自己的lineage信息，当需要时指向已有的RDD，如果遇到failure而失效重新生成构建即可。    
  用户可以控制RDD的持久化机制和分区模式。RDD可以只存储在内存中，也可以只存储在磁盘中，当然也可以采用内存+磁盘的混合存储模式。用户可以指定RDD中的一个key选择合适的partitioner来控制RDD的分区模式，这点与MapReduce的partitioner原理一样。
  
2. ** RDD是如何构建的？**   
  在Spark中RDD通过以下四种方式构建：  
  
  1) *从文件系统*
  
	#Load text file from local FS, HDFS, or S3	
	sc.textFile(“file.txt”)	
	sc.textFile(“directory/*.txt”)	
	sc.textFile(“hdfs://namenode:9000/path/file”)	

  2) *通过Scala集合对象并行化生成*
  
	#Turn a local collection into an RDD	
	sc.parallelize([1,2,3])	

  3) *通过对已存在的RDD transform生成*  
  可以通过对一个已存在的RDD的调用transformation operation（比如map/flatMap/filter etc）生成。Spark提供的transformation operation下章介绍，以下是一些例子：
  
	nums = sc.parallelize([1,2,3])	
	
	# Pass each element through a function 
	squares  = nums.map(lambda x: x*x)	        # => {1, 4, 9}	
	
	# Keep elements passing a predicate	
	even  =	squares.filter(lambda x:  x % 2  == 0)  # => {4}	
	
	# Map each element to zero or more others
	nums.flatMap(lambda x: range(0, x))	        # => {0, 0, 1, 0, 1, 2}	
	
  4) *通过改变其他RDD的持久化状态*  
  RDD是lazy的、临时的。在执行parallel operation时物化创建，用完在内存中销毁。但是用户可以改变cache/save这两种action改变其持久化状态，如下示例：
  
	lines = sc.textFile("hdfs://namenode:9000/path/logfile")
	errors	=  lines.filter(lambda s: s.startswith("ERROR"))
	messages  =  errors.map(lambda s: s.split('\t')[2])
	# cache messages RDD in memory
	messages.cache()
	# save messages RDD to HDFS
	messages.saveAsTextFile("hdfs://namenode:9000/path/errorlogfile")
	
  
###（二）RDD Operations
  Spark与MapReduce的Map-Shuffle-Reduce计算模型不同，它引入了更细粒度的RDD Operation，有以下两类：  
  
  * transformation: 生成RDD，从一个已有RDD转换成另一个RDD，如map/filter等
  * action: 对RDD的操作，比如count/reduce等
  
  Spark目前支持的RDD Operation如下图：  
![Spark Transformations & Actions ](/images/spark_transformations_actions.png)


###（三）Shared Variables
  Spark提供了两种方式来共享变量：
  
  * Broadcast variables: 类似于HDFS的DistributedCache，可用于将小数据分发到各Worker节点，以提高执行效率。如下图所示，利用Broadcast variables实现类似MapReduce的MapJoin：
  
![broadcast_example](/images/spark_broadcast_example.png)
  
  * Accumulators: 类似于MapReduce里的Counter，实现计数统计。如下图所示，利用accumulator实现Counter:

![accumulator_example](/images/spark_accumulator_example.png)


**参考资料**

1. [Resilient Distributed Datasets: A Fault-Tolerant Abstraction for In-Memory Cluster Computing](http://www.cs.berkeley.edu/~matei/papers/2012/nsdi_spark.pdf)  
2. [Spark: Cluster Computing with Working Sets](http://www.cs.berkeley.edu/~matei/papers/2010/hotcloud_spark.pdf)
3. [Parallel Programming With Spark](http://ampcamp.berkeley.edu/wp-content/uploads/2013/02/Parallel-Programming-With-Spark-Matei-Zaharia-Strata-2013.pdf)
4. [Advanced Spark Features](http://ampcamp.berkeley.edu/wp-content/uploads/2012/06/matei-zaharia-amp-camp-2012-advanced-spark.pdf)


