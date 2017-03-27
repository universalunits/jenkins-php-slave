# jenkins-test-slave

1. Start an instance using the desired base AMI (i.e. from [Amazon EC2 AMI Locator](https://cloud-images.ubuntu.com/locator/ec2/)).
2. SSH into the instance and clone this repo.
3. Run the provision script.  

### Using docker to test the configuration

``` bash
docker run --rm -it -v $(pwd):/puppet ubuntu:16.04 /bin/bash
apt-get update && apt-get install -y sudo git && /puppet/provision.sh
```
