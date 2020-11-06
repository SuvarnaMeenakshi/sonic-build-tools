#!/bin/bash -xe

echo ${JOB_NAME##*/}.${BUILD_NUMBER}

ls -l

docker login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWD sonicdev-microsoft.azurecr.io:443
docker pull sonicdev-microsoft.azurecr.io:443/sonic-slave-buster-johnar:latest

cd sonic-buildimage
mkdir -p target

wget -O onie.iso "https://sonicstorage.blob.core.windows.net/packages/onie/onie-recovery-x86_64-kvm_x86_64-r0.iso?sv=2015-04-05&sr=b&sig=XMAk1cttBFM369CMbihe5oZgXwe4uaDVfwg4CTLT%2F5U%3D&se=2155-10-13T10%3A40%3A13Z&sp=r"

if [[ ($1 -gt 1) ]]; then
    MULTIASIC="multiasic-"
else
    MULTIASIC=""
fi

sudo cp /nfs/jenkins/sonic-${MULTIASIC}vs-${JOB_NAME##*/}.${BUILD_NUMBER}.bin target/sonic-${MULTIASIC}vs.bin
sudo rm /nfs/jenkins/sonic-${MULTIASIC}vs-${JOB_NAME##*/}.${BUILD_NUMBER}.bin

docker run --rm=true --privileged -v $(pwd):/data -w /data -i sonicdev-microsoft.azurecr.io:443/sonic-slave-buster-johnar bash -c "SONIC_USERNAME=admin PASSWD=YourPaSsWoRd sudo -E ./scripts/build_kvm_image.sh target/sonic-${MULTIASIC}vs.img onie.iso target/sonic-i${MULTIASIC}vs.bin 16 > target/sonic-${MULTIASIC}vs.img.log"

docker run --rm=true --privileged -v $(pwd):/data -w /data -i sonicdev-microsoft.azurecr.io:443/sonic-slave-buster-johnar bash -c "qemu-img convert target/sonic-vs.img -O vhdx -o subformat=dynamic target/sonic-vs.vhdx"

gzip target/sonic-${MULTIASIC}vs.img

if [ -e /nfs/jenkins/sonic-${MULTIASIC}vs-dbg-${JOB_NAME##*/}.${BUILD_NUMBER}.bin ]; then
    sudo cp /nfs/jenkins/sonic-${MULTIASIC}vs-dbg-${JOB_NAME##*/}.${BUILD_NUMBER}.bin target/sonic-${MULTIASIC}vs-dbg.bin
    sudo rm /nfs/jenkins/sonic-${MULTIASIC}vs-dbg-${JOB_NAME##*/}.${BUILD_NUMBER}.bin

    docker run --rm=true --privileged -v $(pwd):/data -w /data -i sonicdev-microsoft.azurecr.io:443/sonic-slave-buster-johnar bash -c "SONIC_USERNAME=admin PASSWD=YourPaSsWoRd sudo -E ./scripts/build_kvm_image.sh target/sonic-${MULTIASIC}vs-dbg.img onie.iso target/sonic-${MULTIASIC}vs-dbg.bin 16 > target/sonic-${MULTIASIC}vs-dbg.img.log"

    docker run --rm=true --privileged -v $(pwd):/data -w /data -i sonicdev-microsoft.azurecr.io:443/sonic-slave-buster-johnar bash -c "qemu-img convert target/sonic-vs-dbg.img -O vhdx -o subformat=dynamic target/sonic-${MULTIASIC}vs-dbg.vhdx"

    gzip target/sonic-${MULTIASIC}vs-dbg.img
fi

rm -rf ../target
mv target ../
