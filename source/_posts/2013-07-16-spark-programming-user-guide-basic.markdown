---
layout: post
title: "Spark Programming User Guide Basic"
date: 2013-07-16 16:27
comments: true
categories: 
---

### 开发环境搭建

  开发Spark最便捷的方式就是利用spark-shell，交互式编程。参考[安装部署篇](http://localhost:4000/blog/2013/07/16/spark-deploy/)本地模式，在本地部署好Spark，打开spark-shell即可。
  
  另一种方式是在自己的project中引用spark的包，开发standalone的Spark Job。用户可以选择自己喜欢的构建工具（sbt/maven etc），构建一个Scala Project，只需要引入spark的包即可。推荐采用sbt构建项目，用eclipse的scala-ide进行开发。下节简单介绍一个简单的SparkHelloWorld项目的构建和开发步骤。

<!--more-->

### 创建第一个SparkHelloWorld Project

  1. 安装sbt： 请参考[这里](http://www.scala-sbt.org/release/docs/Getting-Started/Setup.html)安装sbt，不在此赘述
  2. 添加sbteclipse插件。sbteclipse插件用来生成eclipse project，请参考[这里](https://github.com/typesafehub/sbteclipse)配置。
  3. 安装eclipse scala-ide插件：update site 地址在[这里](http://scala-ide.org/download/current.html)。    *Note：由于Spark是基于Scala 2.9.3构建的，请选择2.9.*版本安装*
  4. 构建第一个SparkHelloWorld项目：  

		hadoop@Aspire-5830TG:~/project/workspace$ mkdir SparkHelloWorld
		hadoop@Aspire-5830TG:~/project/workspace$ cd SparkHelloWorld/
		hadoop@Aspire-5830TG:~/project/workspace/SparkHelloWorld$ ll
		总用量 0
		#编辑build.sbt，添加spark-core依赖
		hadoop@Aspire-5830TG:~/project/workspace/SparkHelloWorld$ vim build.sbt
		name := "SparkHelloWorld"
		version := "1.0"
		scalaVersion := "2.9.3"
		libraryDependencies += "org.spark-project" %% "spark-core" % "0.7.3"
		resolvers ++= Seq(
		  "Akka Repository" at "http://repo.akka.io/releases/",
		  "Spray Repository" at "http://repo.spray.cc/")
		#构建eclipse project
		hadoop@Aspire-5830TG:~/project/workspace/SparkHelloWorld$ sbt eclipse
		[info] Loading global plugins from /home/hadoop/.sbt/plugins
		[info] Set current project to SparkHelloWorld (in build file:/home/hadoop/project/	workspace/SparkHelloWorld/)
		[info] About to create Eclipse project files for your project(s).
		[info] Updating {file:/home/hadoop/project/workspace/SparkHelloWorld/}default-fa0ba0...
		[info] Resolving commons-lang#commons-lang;2.6 ...
		[info] Done updating.
		[info] Successfully created Eclipse project files for project(s):
		[info] SparkHelloWorld
		hadoop@Aspire-5830TG:~/project/workspace/SparkHelloWorld$ ll -a
		总用量 40
		 4 drwxrwxr-x  5 hadoop hadoop  4096  7月 21 16:18 .
		 4 drwxrwxr-x 40 hadoop hadoop  4096  7月 21 16:13 ..
		 4 -rw-rw-r--  1 hadoop hadoop   264  7月 21 16:17 build.sbt
		12 -rw-rw-r--  1 hadoop hadoop 10903  7月 21 16:17 .classpath
		 4 drwxrwxr-x  3 hadoop hadoop  4096  7月 21 16:17 project
		 4 -rw-rw-r--  1 hadoop hadoop   369  7月 21 16:17 .project
		 4 drwxrwxr-x  4 hadoop hadoop  4096  7月 21 16:17 src
		 4 drwxrwxr-x  5 hadoop hadoop  4096  7月 21 16:17 target
		hadoop@Aspire-5830TG:~/project/workspace/SparkHelloWorld$ 
	
  4. 导入eclipse。  
  ![SparkHelloWorld eclipse project ](/images/sparkhelloworld_eclipse_project.png)
  5. 创建第一个SparkHelloWorld Job
	
		import spark.SparkContext
		import spark.SparkContext._
		object SparkHelloWorld {
	  	def main(args: Array[String]): Unit = {
	    
	    	val sc = new SparkContext("local","SparkHelloWorld","/usr/local/spark/spark-release",List	("target/scala-2.9.3/sparkhelloworld_2.9.3-1.0.jar"))
	    	val log = sc.textFile("/var/log/alternatives.log")
	    	val count = log.count()
		    println("log has "+ count + "lines")
		  }
		
		}
	
  6. 打包执行

		#利用sbt打包
		hadoop@Aspire-5830TG:~/project/workspace/SparkHelloWorld$ sbt package
		[info] Loading global plugins from /home/hadoop/.sbt/plugins
		[info] Set current project to SparkHelloWorld (in build file:/home/hadoop/project/	workspace/SparkHelloWorld/)
		[info] Compiling 1 Scala source to /home/hadoop/project/workspace/SparkHelloWorld/target/	scala-2.9.3/classes...
		[info] Packaging /home/hadoop/project/workspace/SparkHelloWorld/target/scala-2.9.3/sparkhelloworld_2.9.3-1.0.jar ...
		[info] Done packaging.
		[success] Total time: 5 s, completed 2013-7-21 16:39:28
		#执行
		hadoop@Aspire-5830TG:~/project/workspace/SparkHelloWorld$ sbt run
		[info] Loading global plugins from /home/hadoop/.sbt/plugins
		[info] Set current project to SparkHelloWorld (in build file:/home/hadoop/project/	workspace/SparkHelloWorld/)
		[info] Running SparkHelloWorld 
		log has 108 lines
		13/07/21 16:39:35 INFO network.ConnectionManager: Selector thread was interrupted!
		[success] Total time: 3 s, completed 2013-7-21 16:39:35
		hadoop@Aspire-5830TG:~/project/workspace/SparkHelloWorld$

  7. 发布到集群运行  

  上述示例是在本地执行，如要发布到集群运行，需要将SparkContext中Master的地址修改为集群Master的地址，打包并添加到Spark的CLASSPATH 。如：

		val sc = new SparkContext("*spark://10.2.6.152:7077*","SparkHelloWorld","/usr/local/spark/spark-release",List("target/scala-2.9.3/sparkhelloworld_2.9.3-1.0.jar"))


### 参考资料
  1. [spark官方文档](http://spark-project.org/docs/latest/quick-start.html)
