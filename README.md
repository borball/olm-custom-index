# olm-custom-index

Execution logs:

```shell
# ./olm-custom-index.sh
creating workspace: /root/olm-4.12/operators/4.12/redhat-operator-index.
fetching full operator index from registry.redhat.io/redhat/redhat-operator-index:v4.12 to /root/olm-4.12/operators/4.12/index-full.yaml.

processing olm files:
[local-storage-operator]: generating olm-package.
[local-storage-operator]: processing olm-channel, generating olm-channel-original.yaml.
[local-storage-operator]: local-storage-operator.v4.12.0-202403082008 is different with the latest version local-storage-operator.v4.12.0-202403241038: will update olm-channel.yaml.
[local-storage-operator]: deleting local-storage-operator.v4.12.0-202403082008 from the entries in olm-channel.
[local-storage-operator]: renaming local-storage-operator.v4.12.0-202403241038 to local-storage-operator.v4.12.0-202403082008 in olm-channel.
[local-storage-operator]: deleting entries whose version is greater than local-storage-operator.v4.12.0-202403082008 in olm-channel.
[local-storage-operator]: deleting versions greater than local-storage-operator.v4.12.0-202403082008 from the skips in olm-channel.
[local-storage-operator]: generating olm-bundles version <= local-storage-operator.v4.12.0-202403082008.
[local-storage-operator]: completed.

[sriov-network-operator]: generating olm-package.
[sriov-network-operator]: processing olm-channel, generating olm-channel-original.yaml.
[sriov-network-operator]: sriov-network-operator.v4.12.0-202402081808 is the latest one, no need update olm-channel.yaml.
[sriov-network-operator]: generating olm-bundles version <= sriov-network-operator.v4.12.0-202402081808.
[sriov-network-operator]: completed.

[ptp-operator]: generating olm-package.
[ptp-operator]: processing olm-channel, generating olm-channel-original.yaml.
[ptp-operator]: ptp-operator.4.12.0-202402081808 is different with the latest version ptp-operator.4.12.0-202403241038: will update olm-channel.yaml.
[ptp-operator]: deleting ptp-operator.4.12.0-202402081808 from the entries in olm-channel.
[ptp-operator]: renaming ptp-operator.4.12.0-202403241038 to ptp-operator.4.12.0-202402081808 in olm-channel.
[ptp-operator]: deleting entries whose version is greater than ptp-operator.4.12.0-202402081808 in olm-channel.
[ptp-operator]: deleting versions greater than ptp-operator.4.12.0-202402081808 from the skips in olm-channel.
[ptp-operator]: generating olm-bundles version <= ptp-operator.4.12.0-202402081808.
[ptp-operator]: completed.

generator /root/olm-4.12/operators/4.12/redhat-operator-index.Dockerfile.
build container image with /root/olm-4.12/operators/4.12/redhat-operator-index.Dockerfile.
STEP 1/6: FROM quay.io/operator-framework/opm:latest
STEP 2/6: ENTRYPOINT ["/bin/opm"]
--> Using cache d551d51bf08e497b68220e2d585f9bce2cb1fb6d652986400cc2311b1de4c66a
--> d551d51bf08
STEP 3/6: CMD ["serve", "/configs", "--cache-dir=/tmp/cache"]
--> Using cache c20dddee54ade9a21f4e402b3e4115596580b3b50815029af1a1db37372f3b06
--> c20dddee54a
STEP 4/6: ADD redhat-operator-index /configs
--> 1407006973e
STEP 5/6: RUN ["/bin/opm", "serve", "/configs", "--cache-dir=/tmp/cache", "--cache-only"]
time="2024-04-17T02:45:47Z" level=warning msg="unable to set termination log path" error="open /dev/termination-log: permission denied"
time="2024-04-17T02:45:47Z" level=info msg="starting pprof endpoint" address="localhost:6060"
--> e5430659386
STEP 6/6: LABEL operators.operatorframework.io.index.configs.v1=/configs
COMMIT hub-helper:5000/operators/redhat-operator-index:v4.12
--> fed15a7dbb3
Successfully tagged hub-helper:5000/operators/redhat-operator-index:v4.12
fed15a7dbb3bf8d19e461ee9a68eeef7f844ebd94fdfdba14b5b5b0f45760b90
push container image hub-helper:5000/operators/redhat-operator-index:v4.12.
Getting image source signatures
Copying blob ac805962e479 skipped: already exists
Copying blob 1df9699731f7 skipped: already exists
Copying blob 4d049f83d9cf skipped: already exists
Copying blob 6fbdf253bbc2 skipped: already exists
Copying blob af5aa97ebe6c skipped: already exists
Copying blob 70c35736547b skipped: already exists
Copying blob 2a92d6ac9e4f skipped: already exists
Copying blob bbb6cacb8c82 skipped: already exists
Copying blob 2388d21e8e2b skipped: already exists
Copying blob 1a73b54f556b skipped: already exists
Copying blob 3f0dbb44ecc4 skipped: already exists
Copying blob c048279a7d9f skipped: already exists
Copying blob 32507d349a70 skipped: already exists
Copying blob b8d71be48f66 done
Copying blob e0e6d48a95fa skipped: already exists
Copying blob 30e6dfec6a76 done
Copying blob 68f9069c5806 skipped: already exists
Copying config fed15a7dbb done
Writing manifest to image destination
Storing signatures

you can use: hub-helper:5000/operators/redhat-operator-index:v4.12 as operator catalog index on your cluster.
```

## Verification

```shell
# oc-mirror list operators --catalog hub-helper:5000/operators/redhat-operator-index:v4.12
NAME                    DISPLAY NAME             DEFAULT CHANNEL
local-storage-operator  Local Storage            stable
ptp-operator            PTP Operator             stable
sriov-network-operator  SR-IOV Network Operator  stable

# oc-mirror list operators --catalog hub-helper:5000/operators/redhat-operator-index:v4.12 --package=ptp-operator --channel=stable
VERSIONS
4.12.0-202303151915
4.12.0-202307071529
4.12.0-202311222150
4.12.0-202401101650
4.12.0-202401190520
4.12.0-202401291234
4.12.0-202306281416
4.12.0-202308291001
4.12.0-202310121526
4.12.0-202305022015
4.12.0-202305270029
4.12.0-202306090942
4.12.0-202307262354
4.12.0-202301231836
4.12.0-202303231115
4.12.0-202304111715
4.12.0-202304211142
4.12.0-202308231047
4.12.0-202402081808
4.12.0-202303301557
4.12.0-202305161442
4.12.0-202307170916
4.12.0-202302061702
4.12.0-202302280915
4.12.0-202309181625
4.12.0-202303021731
4.12.0-202303090016
4.12.0-202310170157
4.12.0-202310241244
4.12.0-202311021630

# oc-mirror list operators --catalog hub-helper:5000/operators/redhat-operator-index:v4.12 --package=local-storage-operator --channel=stable
VERSIONS
4.12.0-202403082008
4.12.0-202301042354
4.12.0-202302061702
4.12.0-202303301557
4.12.0-202310170157
4.12.0-202310241244
4.12.0-202303231115
4.12.0-202401190520
4.12.0-202304111715
4.12.0-202305101515
4.12.0-202306261055
4.12.0-202307170916
4.12.0-202308231047
4.12.0-202302280915
4.12.0-202305022015
4.12.0-202307071529
4.12.0-202311220908
4.12.0-202402081808
4.12.0-202305262042
4.12.0-202306090942
4.12.0-202308291001
4.12.0-202310111001
4.12.0-202310271701
4.12.0-202304190215
4.12.0-202309181625
4.12.0-202311071130
4.12.0-202401291234
4.12.0-202303081116
4.12.0-202307182142
4.12.0-202401101650


```