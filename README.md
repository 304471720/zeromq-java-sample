# README #

This is a demo project of a [PubSub](http://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) application using [∅mq](http://www.zeromq.org/) with Google's [Protocol Buffers](http://code.google.com/p/protobuf/) for serializing data build with [Maven](http://maven.apache.org/).

## ∅mq ##

I have a multi account system, so I have to switch to my administrator account.
	
	su admin 

Install [∅mq](http://www.zeromq.org/) form source (the latest homebrew version `3.2.1-rc2` had some errors that cause jzmq unit tests to fail)

	cd ~/Projects/external
	git clone git://github.com/zeromq/libzmq.git
	cd libzmq
	./autogen.sh
	./configure
	make
	make install

Exit to the normal user

	exit

## jzmq ##

Switch to admun user

	su admin

Install latest [jzmq](https://github.com/zeromq/jzmq)

	cd ~/Projects/external
	git clone git://github.com/zeromq/jzmq.git
	cd jzmq
	./autogen.sh
	./configure
	make
	make install

Test the installation

	cd perf
	java -Djava.library.path=/usr/local/lib -classpath /usr/local/share/java/zmq.jar:../src/zmq.jar:zmq-perf.jar local_lat tcp://127.0.0.1:5555 1 100

At the first run this fails

	...
	Library not loaded: /usr/local/lib/libzmq.1.dylib
	  Referenced from: /usr/local/lib/libjzmq.0.dylib

And indeed the file does not exist, but `libzmq.3.dylib` does exist, so

	ln -s /usr/local/lib/libzmq.3.dylib /usr/local/lib/libzmq.1.dylib

Rerun the perf test
	
	java -Djava.library.path=/usr/local/lib -classpath /usr/local/share/java/zmq.jar:../src/zmq.jar:zmq-perf.jar local_lat tcp://127.0.0.1:5555 1 100
	java -Djava.library.path=/usr/local/lib -classpath /usr/local/share/java/zmq.jar:../src/zmq.jar:zmq-perf.jar remote_lat tcp://127.0.0.1:5555 1 100

Proceed to compile the maven artifact

	cd ..
	export JAVA_HOME=`/usr/libexec/java_home -v 1.7`
	mvn clean install -DskipTests

Exit to the normal user

	exit

## Maven and jzmq ##

Although jzmq's official [maven.readme](https://github.com/zeromq/jzmq/blob/master/maven.readme) advices you to add a dependency to the native artifact, I didn't work. In fact it [did only work without](http://lists.zeromq.org/pipermail/zeromq-dev/2012-November/019265.html) the native library. 

So just add

	<dependency>
		<groupId>org.zeromq</groupId>
		<artifactId>jzmq</artifactId>
		<version>${version.jzmq}</version>
	</dependency>

to your dependencies.

## Protocol Buffers ##

I want to use Google's [Protocol Buffers](http://code.google.com/p/protobuf/) as the serializing mechanism

> Protocol Buffers are a way of encoding structured data in an efficient yet extensible format. Google uses Protocol Buffers for almost all of its internal RPC protocols and file formats.

	brew install protobuf

There is a Maven plugin to build `.proto` files. It's not released on Maven Central, so you have to add the plugin repository to your `$M2_HOME/settings.xml`. In this example I added it directly to the `pom.xml` though.

	<pluginRepositories>
        <pluginRepository>
            <id>protoc-plugin</id>
            <url>http://sergei-ivanov.github.com/maven-protoc-plugin/repo/releases/</url>
        </pluginRepository>
    </pluginRepositories>

To include the generated source in Eclipse with m2eclipse. You also have to add

	<plugin>
		<groupId>org.codehaus.mojo</groupId>
		<artifactId>build-helper-maven-plugin</artifactId>
		<executions>
			<execution>
				<id>add-source</id>
				<phase>generate-sources</phase>
				<goals>
					<goal>add-source</goal>
				</goals>
				<configuration>
					<sources>
						<source>${project.build.directory}/generated-sources/protoc</source>
					</sources>
				</configuration>
			</execution>
		</executions>
	</plugin>

to your `pom.xml`.

## Appendix ##

### FAQ ###

#### `java.lang.UnsatisfiedLinkError` ####

	Exception in thread "main" java.lang.UnsatisfiedLinkError: /usr/local/lib/libjzmq.0.dylib: dlopen(/usr/local/lib/libjzmq.0.dylib, 1): Library not loaded: /usr/local/lib/libzmq.1.dylib
	  Referenced from: /usr/local/lib/libjzmq.0.dylib
	  Reason: image not found
		at java.lang.ClassLoader$NativeLibrary.load(Native Method)
		at java.lang.ClassLoader.loadLibrary1(ClassLoader.java:1939)
		at java.lang.ClassLoader.loadLibrary0(ClassLoader.java:1864)
		at java.lang.ClassLoader.loadLibrary(ClassLoader.java:1854)
		at java.lang.Runtime.loadLibrary0(Runtime.java:845)
		at java.lang.System.loadLibrary(System.java:1084)
		at org.zeromq.ZMQ.<clinit>(ZMQ.java:35)
		at local_lat.main(local_lat.java:36)

There is a `/usr/local/lib/libzmq.3.dylib` but no `/usr/local/lib/libzmq.3.dylib`.

As a workaround I executed

	ln -s /usr/local/lib/libzmq.3.dylib /usr/local/lib/libzmq.1.dylib

#### `dyld: DYLD_ environment variables being ignored` ###

When trying to fix my zeromq installation I got

	dyld: DYLD_ environment variables being ignored because main executable (/usr/bin/sudo) is setuid or setgid

Turned out `$LD_LIBRARY_PATH` was set. Unset it via

	unset LD_LIBRARY_PATH 

#### `testDestruction(org.zeromq.ZContextTest): no jzmq in java.library.path` ####

	cd ~/Projects/external/jzmq
	mvn clean install

fails with

	Tests in error: 
	  testDestruction(org.zeromq.ZContextTest): no jzmq in java.library.path
	  ...

*What is `java.library.path`*

`java.library.path` is used for pointing to native system libraries (dll or so files). It points to a directory and calls to native code that use System.loadLibrary look in that directory for the native libs.

The project dependencies (jar files) should be specified on the application's classpath, not in this location.

from [1](http://stackoverflow.com/a/4195049/256853)

#### `Failed to execute goal org.apache.maven.plugins:maven-javadoc-plugin` ####

As I couldn't get the tests to finish I did

	mvn clean install -DskipTests

But was greeted with

	[ERROR] Failed to execute goal org.apache.maven.plugins:maven-javadoc-plugin:2.7:jar (attach-javadoc) on project jzmq: MavenReportException: Error while creating archive:Unable to find javadoc command: The environment variable JAVA_HOME is not correctly set.

Make sure `JAVA_HOME` is set. If you have Java 6

	export JAVA_HOME=`/usr/libexec/java_home -v 1.6`

or Java 7

	export JAVA_HOME=`/usr/libexec/java_home -v 1.7`

#### junit.framework.AssertionFailedError ####

Unfortunately the Maven tests for jzmq ddidn't finish (correctly).

	singleMessage(org.zeromq.ZDispatcherTest)  Time elapsed: 1.01 sec  <<< FAILURE!
	junit.framework.AssertionFailedError: expected:<0> but was:<1>

and even worse `Running org.zeromq.ZFrameTest` seems to be stuck in an endless loop.

The mailing list [suggested](http://lists.zeromq.org/pipermail/zeromq-dev/2012-November/019262.html) to remove homebrews latest version (`3.2.1-rc2`) and install libzmq from source.

This solved the problems with the tests.

#### Install zeromq from source ####

The mailing list suggested to install zeromq from source

	brew remove zeromq
	git clone git://github.com/zeromq/libzmq.git
	cd libzmq/
	./autogen.sh
	./configure
	make
	make install

Testing the installation with perf failed at first
	
	cd perf
	java -Djava.library.path=/usr/local/lib -classpath /usr/local/share/java/zmq.jar:../src/zmq.jar:zmq-perf.jar local_lat tcp://127.0.0.1:5555 1 100
	...
	Library not loaded: /usr/local/lib/libzmq.1.dylib
	  Referenced from: /usr/local/lib/libjzmq.0.dylib

So, I executed

	ln -s /usr/local/lib/libzmq.3.dylib /usr/local/lib/libzmq.1.dylib

Then I recompiled jzmq

	cd ../jzmq
	make clean
	make
	make install

Now the tests successfully ran, so installed the artifact

	export JAVA_HOME=`/usr/libexec/java_home -v 1.7`
	mvn clean install

### Resources ###

The code example for protocol buffers is taken from [2](http://stackoverflow.com/a/12109477/256853) and the basic pubsub example is taken from ∅mq official java examples [3](http://zguide.zeromq.org/java:psenvpub), and [4](http://zguide.zeromq.org/java:psenvsub)
