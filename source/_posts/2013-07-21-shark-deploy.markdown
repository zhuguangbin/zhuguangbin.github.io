---
layout: post
title: "Shark安装部署与应用"
date: 2013-07-21 23:07
comments: true
categories: 
---

  在搭建部署Spark之后，我们又引入了[Shark](https://github.com/amplab/shark/wiki)，一个基于Spark的SQL引擎来替换Hive作为adhoc query engine。我的[这篇博客](http://zhuguangbin.github.io/blog/2013/07/09/shark-introduction/)对Shark有简单的介绍。
  我们引入Shark是希望利用Spark的性能，提高Hive的执行效率，提供adhoc的interactive的快速查询，并与Spark集成访问Shark的表数据做一些interative算法比如Machine Learning。这样我们的在Hadoop上的任务可以分为以下几类：
  
  1. Batch Job：如ETL，全量历史记录数据处理与统计等等，采用MapReduce Job或者Hive Job。
  2. Adhoc Query：如ba的报表统计，销售人员的临时查询等等，采用Shark Job。
  3. Interative Job：如算法组的个性化推荐，采用Shark或者Spark Job。
  4. Streaming Job：如实时推荐，采用Storm或者Spark-Streaming。
  
  本篇首先介绍Shark的安装部署配置，然后介绍我们在将Shark集成到我们的Hadoop集群中遇到的一些坑和我们的解决方案。

<!--more-->

 
### 版本选择

  * Hadoop: 1.0.3
  * Hive: 0.9.0 amp-patched version
  * Spark: 0.7.3
  * Shark: 0.7.0
  
> Note: Shark 0.7.0依赖的Hive版本是amplab自己基于apache官方0.9.0版本打过自己的patch的[版本](https://github.com/amplab/hive/tree/amp-0.9-20130517)，而我们自己的[cosmos-hadoop-0.9.0版本](https://github.com/dianping/hive/tree/cosmos-hadoop-0.9.0)也是基于apache官方0.9.0修复而来。将amp的版本与我们的版本compare了一下(github的[compare url](https://github.com/amplab/hive/compare/dianping:cosmos-hadoop-0.9.0...amp-0.9-20130517))，发现amplab的版本与我们的版本的主要区别在于我们的HiveServer是支持Security的，而amplab的不支持。所以Shark v0.7.0的Hive Server不支持Security。
> 我们后续会将Shark对Hive的依赖迁移到我们的cosmos-hadoop-0.9.0版本。

### 前提条件
  1. 集群部署并配置好Hadoop和Spark
  2. 安装部署并配置好Hive

### 安装配置

  Shark的安装配置很简单，只需要下载安装包解压并进行简单的配置即可。*Note：注意hive的依赖*

1. download Shark和amp-patched hive的压缩包，并解压
  
		cd /usr/local/spark
		wget http://spark-project.org/download-hive-0.9.0-bin.tar.tz
		tar zxvf download-hive-0.9.0-bin.tar.tz
		wget http://spark-project.org/download/shark-0.7.0-hadoop1-bin.tgz
		tar zxvf shark-0.7.0-hadoop1-bin.tgz
		ln -s shark-0.7.0 shark-release
		
		ls -l
		总用量 82924
		drwxr-xr-x  7 hadoop hadoop     4096 7月  20 16:42 hive-0.9.0-bin
		-rw-r--r--  1 hadoop hadoop 22711471 10月 15 2012 hive-0.9.0-bin.tar.gz
		drwxr-xr-x 11 hadoop hadoop     4096 7月   3 17:53 shark-0.7.0
		lrwxrwxrwx  1 hadoop hadoop       11 7月  14 16:02 shark-release -> shark-0.7.0
		drwxr-xr-x 18 hadoop hadoop     4096 7月  20 17:09 spark-0.7.3
		-rw-r--r--  1 hadoop hadoop 62187714 7月  17 05:29 spark-0.7.3-prebuilt-hadoop1.tgz
		lrwxrwxrwx  1 hadoop hadoop       11 7月  20 16:49 spark-release -> spark-0.7.3
		
2. 配置Shark:

	* 添加环境变量，如下：
   
			vim /etc/profile
			export SHARK_HOME=/usr/local/spark/shark-release
			export PATH=$SHARK_HOME/bin:$PATH
		
	* 配置Shark：Shark的配置文件只有一个:$SHARK_HOME/conf/shark-env.sh

			export SPARK_MEM=4g
		
			 # (Required) Set the master program's memory
			export SHARK_MASTER_MEM=1g
		
			 # (Required) Point to your Scala installation.
			export SCALA_HOME=/usr/local/scala/
		
			 # (Required) Point to the patched Hive binary distribution
			export HIVE_HOME=/usr/local/spark/hive-0.9.0-bin
		
			 # (Optional) Specify the location of Hive's configuration directory. By default,
			 # it points to $HIVE_HOME/conf
			export HIVE_CONF_DIR="$HIVE_HOME/conf"
		
			 # For running Shark in distributed mode, set the following:
			export HADOOP_HOME=/usr/local/hadoop/hadoop-release/
			export SPARK_HOME=/usr/local/spark/spark-release/
			export MASTER=spark://10.2.6.152:7077
		
			source $SPARK_HOME/conf/spark-env.sh
		
			 # LZO compression native lib
			export LD_LIBRARY_PATH=/usr/local/hadoop/lzo/lib

			 # (Optional) Extra classpath
			export SPARK_LIBRARY_PATH=/usr/local/hadoop/hadoop-release/lib/native/Linux-amd64-64

			 # Java options
			 # On EC2, change the local.dir to /mnt/tmp
			SPARK_JAVA_OPTS="-Dspark.local.dir=/tmp "
			SPARK_JAVA_OPTS+="-Dspark.kryoserializer.buffer.mb=10 "
			 #SPARK_JAVA_OPTS+="-verbose:gc -XX:-PrintGCDetails -XX:+PrintGCTimeStamps "
			SPARK_JAVA_OPTS+="-XX:MaxPermSize=256m "
			SPARK_JAVA_OPTS+="-Dspark.cores.max=12 "
			export SPARK_JAVA_OPTS

		
3. 将Shark以及Hive的安装配置分发到Spark集群的各个节点
  > NOTE：Shark只是一个Client Driver将SQL转化成Spark Job，为什么需要将Shark和Hive的包分发到各个节点呢？其实这样做的目的是将Shark和Hive的jar包加载到Spark StandaloneBackEnd的CLASSPATH里，让Executor启动时加载Shark和Hive的jar包。我尝试不分发Shark和Hive的包，而只将Hive的jar包放到Spark的lib目录下，同样work，否则会包ClassNotFound错误。为了更加方便的管理，还是将Spark和Hive的包分发到各个节点上。
  
4. 将客户端的Hive换为我们版本的Hive，修改shark-env.sh，将HIVE_HOME只向我们版本的Hive
  
		export HIVE_HOME=/usr/local/hadoop/hive-release
  > NOTE: 为什么这样做？因为Shark也只是个客户端而已，我们版本的Hive添加了我们自己的一些特性，如比权限验证，我们不允许用户有grant权限，不允许用户set一些重要的HiveConf。而这些是amp的hive没有的。因此，客户端指向我们自己的Hive，而各个节点用amplab的版本就可以。
  
5. 测试验证：
  
		[hadoop@cosmos155 conf]$ shark
		
		Starting the Shark Command Line Client
		WARNING: org.apache.hadoop.metrics.jvm.EventCounter is deprecated. Please use org.apache.hadoop.log.metrics.EventCounter in all the log4j.properties files.
		Logging initialized using configuration in jar:file:/usr/local/hadoop/hive-0.9.0/lib/hive-common-0.9.0.jar!/hive-log4j.properties
		Hive history file=/data/hive-query-log/hadoop/hive_job_log_hadoop_201307221453_1130459904.txt
		shark (default)> show tables;
		OK
		device_permanent_city
		dpmid_dp_shop_his_2012
		dpmid_tg_receipt_add
		dpods_mc_table_info
		hippolog
		hippolog_input_nosort
		hippolog_input_sort
		hippologcurrent
		jinss_test_1129
		lzo_rcfile_test
		nginx
		nginx_bak
		nginx_search_condition
		nginx_temp
		nginxlogcurrent
		nginxlogcurrenttmp
		range_keys
		rcfilenginx_gz
		search_log
		searchexec
		test
		Time taken: 3.03 seconds
		shark> 


### 我们遇到的一些坑


1. Security问题：

	* 描述：由于我们的Hadoop集群启用了kerberos认证，而Spark目前是不支持Kerberos的，所以，访问HDFS时报如下错误：
	
			javax.security.sasl.SaslException: GSS initiate failed [Caused by GSSException: No valid credentials provided (Mechanism level: Failed to find any Kerberos tgt)]  
			
	* 解决方案：为每一个Spark节点创建一个principal: shark/_HOST@DIANPING.COM，并生成keytab。将shark加入所有组，使其有所有表的读权限。然后，起一个crontab定时执行kinit去KDC拿一张票，保证Spark在向HDFS读取文件时有shark的ticket cache。
  
2. 文件权限问题：
  
	* 描述：基于上一个问题的解决方案，这样客户端提交SQL的用户principal是用户自己，如guangbin.zhu，其为本次Job创建了一个scrachdir(/tmp/hive-guangbin.zhu/{jobname})，owner是guangbin.zhu，group是guangbin.zhu的group:op。但发到Spark集群真正执行处理的principal是shark，这样就导致shark用户无权访问guangbin.zhu的scrachdir而报错。
	* 解决方案：在shark启动时，set dfs.umaskmode=000，在Spark集群的hive-site.xml中也添加dfs.umaskmode=000配置。这样强制将本次Shark Job的hdfs的权限设为每个人都有权限读写。
  
3. 并发问题：
  
	* 描述：目前Spark Standalone模式只支持FIFO调度，默认每个Job会占有所有的集群资源，而后续的Job会一直等待直到它退出。这将影响集群多用户的使用，当一个用户执行shark时，其他人只能等待他执行完。
	* 解决方案：通过查看文档，Spark支持用户配置其使用的cpu core数，通过以下配置，限定每个shark job的资源占用：

	  		#每个Spark Job的Worker Executor使用4G内存
			export SPARK_MEM=4g
			#每个Spark Job最大占用12个CPU core
			SPARK_JAVA_OPTS+="-Dspark.cores.max=12 "

4. 权限问题：
  
	* 描述：我们的Hive启用了authorization，而shark v0.7.0中没有authorization，即所有人对所有表拥有所有权限，这不符合我们的需求。
	* 解决方案：修改代码，修复bug，见[github commit](https://github.com/zhuguangbin/shark/commit/93aa994db81512d4bfe6bee6a94cc198f6970fde)

> Note: 在build Shark时，一定要选择amplab patched的HIVE_HOME，否则build出来的shark的SharkSemanticAnalyzer会有问题。我们后续将对Hive的依赖迁移到我们的Hive版本。


5. ArrayIndexOutOfBoundsException:
  
	* 描述：在偶尔情况下，会产生如下错误：


			13/07/23 11:14:07 WARN lazybinary.LazyBinaryStruct: Extra bytes detected at the end of the row! Ignoring similar problems.
			13/07/23 11:14:07 ERROR executor.Executor: Exception in task ID 50
			java.lang.ArrayIndexOutOfBoundsException
				at java.lang.System.arraycopy(Native Method)
				at org.apache.hadoop.io.Text.set(Text.java:205)
				at org.apache.hadoop.hive.serde2.lazybinary.LazyBinaryString.init(LazyBinaryString.java:48)
				at org.apache.hadoop.hive.serde2.lazybinary.LazyBinaryStruct.uncheckedGetField(LazyBinaryStruct.java:216)
				at org.apache.hadoop.hive.serde2.lazybinary.LazyBinaryStruct.getField(LazyBinaryStruct.java:197)
				at org.apache.hadoop.hive.serde2.lazybinary.objectinspector.LazyBinaryStructObjectInspector.getStructFieldData(LazyBinaryStructObjectInspector.java:61)
				at org.apache.hadoop.hive.ql.exec.ExprNodeColumnEvaluator.evaluate(ExprNodeColumnEvaluator.java:102)
				at shark.execution.JoinOperator$$anonfun$generateTuples$1.apply(JoinOperator.scala:169)
				at shark.execution.JoinOperator$$anonfun$generateTuples$1.apply(JoinOperator.scala:154)
				at scala.collection.Iterator$$anon$19.next(Iterator.scala:401)
				at scala.collection.Iterator$$anon$21.next(Iterator.scala:441)
				at scala.collection.Iterator$$anon$19.next(Iterator.scala:401)
				at scala.collection.Iterator$class.foreach(Iterator.scala:772)
				at scala.collection.Iterator$$anon$19.foreach(Iterator.scala:399)
				at shark.execution.FileSinkOperator.processPartition(FileSinkOperator.scala:73)
				at shark.execution.FileSinkOperator$.writeFiles$1(FileSinkOperator.scala:158)
				at shark.execution.FileSinkOperator$$anonfun$executeProcessFileSinkPartition$1.apply(FileSinkOperator.scala:162)
				at shark.execution.FileSinkOperator$$anonfun$executeProcessFileSinkPartition$1.apply(FileSinkOperator.scala:162)
				at spark.scheduler.ResultTask.run(ResultTask.scala:77)
				at spark.executor.Executor$TaskRunner.run(Executor.scala:98)
				at java.util.concurrent.ThreadPoolExecutor$Worker.runTask(ThreadPoolExecutor.java:895)
				at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:918)
				at java.lang.Thread.run(Thread.java:662)
	

	* 原因：apache 官方hive的版本存在concurrency问题。感谢Intel的[jerryshao](http://weibo.com/u/2122584747)的建议。sharkuser的google group上有人讨论这个问题，见这个[topic](https://groups.google.com/forum/#!searchin/shark-users/java.lang.ArrayIndexOutOfBoundsException/shark-users/QcrcV5BPPek/Bue9Cp2Zk5wJ)
	* 解决方案：采用amplab的hive版本，修复掉了concurrency问题。后续，我们将梳理amplab的hive版本与我们自己版本的差异，让shark依赖我们自有版本的hive而不是amplab的版本。
	
### 参考资料

1. [shark on github](https://github.com/amplab/shark)
2. [shark 官方wiki](https://github.com/amplab/shark/wiki)
3. [shark introductin slide](http://ampcamp.berkeley.edu/wp-content/uploads/2013/02/Shark-SQL-and-Rich-Analytics-at-Scala-Reynold-Xin.pdf)
  

  
  
