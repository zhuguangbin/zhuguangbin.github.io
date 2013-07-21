---
layout: post
title: "Spark安装部署篇"
date: 2013-07-16 11:58
comments: true
categories: 
---

  Spark有以下四种运行模式：

* local: 本地单进程模式，用于本地开发测试Spark代码
* standalone：分布式集群模式，Master-Worker架构，Master负责调度，Worker负责具体Task的执行 
* on yarn/mesos: ‌运行在yarn/mesos等资源管理框架之上，yarn/mesos提供资源管理，spark提供计算调度，并可与其他计算框架(如MapReduce/MPI/Storm)共同运行在同一个集群之上
* on cloud(EC2): 运行在AWS的EC2之上

本章主要介绍本地模式和standalone模式的安装部署配置。

###本地模式
  *注: 本文只介绍Linux的安装部署配置方式，Windows以及Mac下类似，用户请自行参考官方文档*


####1. 前提条件  
  
  Spark依赖JDK 6.0以及Scala 2.9.3以上版本，所以首先确保已安装JDK和Scala的合适版本并加入PATH。
  本节比较简单，不在此赘述。安装完毕，请验证JDK和Scala的版本

	hadoop@Aspire-5830TG:~$ echo $JAVA_HOME
	/usr/local/jdk
	hadoop@Aspire-5830TG:~$ java -version
	java version "1.6.0_43"
	Java(TM) SE Runtime Environment (build 1.6.0_43-b01)
	Java HotSpot(TM) 64-Bit Server VM (build 20.14-b01, mixed mode)
	  
	hadoop@Aspire-5830TG:~$ echo $SCALA_HOME
	/usr/local/scala
	hadoop@Aspire-5830TG:~$ scala
	Welcome to Scala version 2.9.3 (Java HotSpot(TM) 64-Bit Server VM, Java 1.6.0_43).
	Type in expressions to have them evaluated.
	Type :help for more information.
	
	scala> 

####2. 安装Spark  
  
  Spark的安装和简单，只需要将Spark的安装包download下来，加入PATH即可。我们采用官方v0.7.2版本  

	cd /user/local  
	wget http://spark-project.org/download/spark-0.7.2-prebuilt-hadoop1.tgz 
	tar zxvf spark-0.7.2-prebuilt-hadoop1.tgz  
	ln -s spark-0.7.2 spark-release  
	
	vim /etc/profile  
	export SPARK_HOME=/usr/local/spark-release
	export PATH=$SPARK_HOME/bin
	
	
####3. 配置Spark  
  
  Spark的配置文件只有一个: $SPARK_HOME/conf/spark-env.sh。本地开发模式的配置很简单，只需要配置JAVA_HOME和SCALA_HOME。实例如下：  

	export JAVA_HOME=/usr/local/jdk  
	export SCALA_HOME=/usr/local/scala  
	# add spark example jar to CLASSPATH  
	export SPARK_EXAMPLES_JAR=$SPARK_HOME/examples/target/scala-2.9.3/spark-examples_2.9.3-0.7.2.jar  
	
  
####4. 测试验证  
  
  Spark提供了两种运行模式：
  
  1) run脚本: 用于运行已经生成的jar包中的代码，如Spark自带的example中的SparkPi。  

	hadoop@Aspire-5830TG:/usr/local/spark-release$ ./run  spark.examples.SparkPi local
	
	# 此处略去一万字....
	Pi is roughly 3.1358

  2) spark-shell: 用于interactive programming
  
	hadoop@Aspire-5830TG:/usr/local/spark-release$ ./spark-shell 
	Welcome to
	      ____              __  
	     / __/__  ___ _____/ /__
	    _\ \/ _ \/ _ `/ __/  '_/
	   /___/ .__/\_,_/_/ /_/\_\   version 0.7.2
	      /_/                  
	
	Using Scala version 2.9.3 (Java HotSpot(TM) 64-Bit Server VM, Java 1.6.0_43)
	Initializing interpreter...
	13/07/16 15:28:04 WARN Utils: Your hostname, Aspire-5830TG resolves to a loopback address: 127.0.0.1; using 172.16.239.1 instead (on interface vmnet8)
	13/07/16 15:28:04 WARN Utils: Set SPARK_LOCAL_IP if you need to bind to another address
	Creating SparkContext...
	Spark context available as sc.
	Type in expressions to have them evaluated.
	Type :help for more information.
	
	scala> val days = List("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
	days: List[java.lang.String] = List(Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday)
	
	scala> val daysRDD = sc.parallelize(days)
	daysRDD: spark.RDD[java.lang.String] = ParallelCollectionRDD[0] at 	parallelize at <console>:14
	
	scala> daysRDD.count()
	res0: Long = 7
	
	scala> 

###Standalone模式
	
  *Note：Spark是Master-Worker架构，在部署之前需要确定Master/Worker机器。同时，分布式集群模式要共享HDFS上的数据，因此需要在每个节点安装Hadoop。*
  
####1. 前提条件  

  * 集群模式下，Master节点要能够*ssh无密码登陆*各个Worker节点。 
  * 与本地模式一样，Spark集群的*每个节点*需要安装JDK和Scala。 
  * Spark集群的*每个节点*需要安装Hadoop（作为hadoop client访问HDFS上的数据）。 
  
####2. 安装Spark  
  
  与本地环境一样，Spark集群的*每个节点*需要download spark的tar.gz包，解压，并配置环境变量。  

####3. 配置Spark  

  分布式集群模式下，Spark的配置文件有两个:
  
  * $SPARK_HOME/conf/slaves
  
  slaves 是一个文本文件，将各个worker节点的IP加进去，一行一个，示例如：
  
	10.2.6.133
	10.2.6.134
	10.2.6.154

  * $SPARK_HOME/conf/spark-env.sh文件：
  
  Spark的环境配置文件，定义Spark的Master/Worker以及资源定义，示例如：

	export JAVA_HOME=/usr/local/jdk 
	export SCALA_HOME=/usr/local/scala
	
	# SSH related
	export SPARK_SSH_OPTS="-p58422 -o StrictHostKeyChecking=no"
	
	# Spark Master IP
	export SPARK_MASTER_IP=10.2.6.152 
	# set the number of cores to use on worker
	export SPARK_WORKER_CORES=16
	# set how much memory to use on worker
	export SPARK_WORKER_MEMORY=16g
	
	export SPARK_EXAMPLES_JAR=/usr/local/spark-0.7.2/examples/target/scala-2.9.3/spark-examples_2.9.3-0.7.2.jar
	
	# LZO codec related
	export LD_LIBRARY_PATH=/usr/local/hadoop/lzo/lib
	export SPARK_LIBRARY_PATH=/usr/local/hadoop/hadoop-release/lib/native/Linux-amd64-64/  
	
  在Spark集群的*每个节点*上配置好以上两个配置文件
    
####4. 启动集群  
  
  在*Master*节点上，执行如下命令：
  
	[hadoop@cosmos152 spark-release]$ echo $SPARK_HOME
	/usr/local/spark-release
	[hadoop@cosmos152 spark-release]$ bin/start-all.sh 
	starting spark.deploy.master.Master, logging to /usr/local/spark-0.7.2/bin/../logs/spark-hadoop-spark.deploy.master.Master-1-cosmos152.hadoop.out
	Master IP: 10.2.6.152
	cd /usr/local/spark-0.7.2/bin/.. ; /usr/local/spark-release/bin/start-slave.sh 1 spark://10.2.6.152:7077
	10.2.6.133: starting spark.deploy.worker.Worker, logging to /usr/local/spark-0.7.2/bin/../logs/spark-hadoop-spark.deploy.worker.Worker-1-cosmos133.hadoop.out
	10.2.6.134: starting spark.deploy.worker.Worker, logging to /usr/local/spark-0.7.2/bin/../logs/spark-hadoop-spark.deploy.worker.Worker-1-cosmos134.hadoop.out
	10.2.6.154: starting spark.deploy.worker.Worker, logging to /usr/local/spark-0.7.2/bin/../logs/spark-hadoop-spark.deploy.worker.Worker-1-cosmos154.hadoop.out
	[hadoop@cosmos152 spark-release]$ 
	
####5. 测试验证  
  推荐部署一个Client节点上，专门用于Spark Job的提交。配置与上述节点一致。在Client节点上，执行以下命令：
  
	hadoop@cosmos155:/usr/local/spark-release$ ./run  spark.examples.SparkPi spark://10.2.6.152:7077
	
	# 此处略去一万字....
	Pi is roughly 3.1358
	
	
###参考资料：

1. [Spark Overview](http://spark-project.org/docs/latest/index.html)
2. [Standalone Deploy Mode](http://spark-project.org/docs/latest/spark-standalone.html)




