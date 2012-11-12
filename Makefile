all:
	cd protobuf && mvn clean install
	cd pub && mvn clean install
	cd sub && mvn clean install