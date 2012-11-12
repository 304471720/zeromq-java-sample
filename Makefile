all:
	cd protobuf && mvn clean package
	cd pub && mvn clean package
	cd sub && mvn clean package