# Hãy luôn nhớ cơ chế của ETCD hoạt động => Từ đó biết cách Back-up như thế nào là hợp lý.
## Tạo Snapshot
rke2 etcd-snapshot save --name pre-upgrade-snapshot
(The snapshot directory defaults to /var/lib/rancher/rke2/server/db/snapshots)
## Cluster reset
1. systemctl stop rke2-server
2. rke2 server --cluster-reset
(RKE2 sẽ reset metadata của etcd.Thiết lập node hiện tại thành leader duy nhất.Không xoá data, chỉ reset cluster config)
=> Start RKE2 again and it should start RKE2 as a 1 member cluster.

## Restoring a Snapshot to Existing Nodes
1. systemctl stop rke2-server 
(Stop tất cả các master node còn lại => đồng bộ dữ liệu)
2. rke2 server \
  --cluster-reset \
  --cluster-reset-restore-path=<PATH-TO-SNAPSHOT>
(Node nàp chạy lệnh này ở master mấy. ">" nhá)
3. systemctl start rke2-server
(Node nàp chạy lệnh này ở master mấy. ">" nhá)
4. rm -rf /var/lib/rancher/rke2/server/db
(Node nàp chạy lệnh này ở master mấy. "#>" nhá)
5. systemctl start rke2-server

**Note**
Sau khi khôi phục thành công, trong log sẽ xuất hiện thông báo cho biết etcd đã chạy, và RKE2 có thể được khởi động lại mà không cần các tham số (flag) nữa. Hãy khởi động lại RKE2, và nó sẽ chạy thành công, được khôi phục từ snapshot đã chỉ định.

Khi RKE2 reset cluster, nó tạo một file: /var/lib/rancher/rke2/server/db/reset-flag . File này không gây ảnh hưởng gì nếu để nguyên, nhưng bắt buộc phải xóa nếu bạn muốn thực hiện reset hoặc restore một lần nữa. File này sẽ tự động bị xóa khi RKE2 khởi động bình thường.

## Restoring a Snapshot to New Nodes
1. Back up the token server: /var/lib/rancher/rke2/server/token in case you will not use the same one. The token server is used to decrypt the bootstrap data inside the snapshot.
2. Stop RKE2 service on all server nodes if it is enabled and initiate the restore from snapshot on the first server node with the following commands:

systemctl stop rke2-server
rke2 server \
  --cluster-reset \
  --cluster-reset-restore-path=<PATH-TO-SNAPSHOT>
  --token=<BACKED-UP-TOKEN-VALUE>

3. Once the restore process is complete, start the rke2-server service on the first server node as follows:

systemctl start rke2-server

4. Add node lại