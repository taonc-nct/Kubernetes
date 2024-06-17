# Kubernetes

1.  **- Question:** StatefulSet, DeamonSet, Deployment là gì. Phân biệt giữa chúng và cách dùng của chúng.

    **- Answer:**

    - Deployment:
        - Tổng quát: 
            1. Các Pod của Deployment là hoàn toàn giống nhau (Identical) và có thể thay thế lẫn nhau về chức năng. Nghĩa là một Pod bị lỗi thì hoàn toàn có thể thay thế bằng một Pod mới để tiếp tục xử lý.
            2. Deployment trước tiên sẽ sinh ra các Replicaset, sau đó ReplicaSet mới tạo ra các Pod theo thứ tự ngẫu nhiên. Tên Pod cũng theo format tên của Replicaset + mã hash random gán vào đuôi mỗi Pod.
            ![alt text](../img/4.webp)
            3. Các Pod của Deployment cũng có thể bị xóa theo thứ tự bất kỳ, hoặc xóa đồng thời nhiều Pod (trong trường hợp scale down deployment)
        - PVC: 
            1. Các pod của Deployment có stogare chung (cùng một vùng lưu trữ(pvc)).
                ![alt text](../img/1.webp)
        - Note: 
            - Deployment thích hợp triển khai các stateless app
    - Statefulset: 
        - Tổng quát:
            1. Các Pod của Statefulset không thể được tạo hay xóa cùng lúc. Nó sẽ được tạo tuần tự.
            2. Các Pod của Statefuleset không hoàn toàn giống nhau. Statefulset cung cấp stable identity có dạng pod-0, pod-1...(sẽ được gán với một index, index này sẽ được sử dụng để định danh cho mỗi Pod). Không chỉ có định danh riêng(stable indentity) mà mỗi pod có một stable network indentity -> Điều này thể hiện tính bảo toàn khi một pod xóa đi statefulset sẽ tạo ra một pod giống(stable identity, stable network indentity) như pod đã bị xóa.
            3. Các Pod được tạo với các mô tả giống nhau (specification) nhưng không thể thay thế lẫn nhau (not interchangeable)
            4. Khi một Pod bị lỗi nó sẽ được thay thế bằng một Pod mới cùng định danh (ví dụ pod-1 bị lỗi sẽ được thay bằng Pod mới nhưng tên vẫn là pod-1).
        - PVC: 
            1. Các pod của StatefulSet có stogare riêng (vùng lưu trữ khác nhau(pvc)). Nghĩa là có bao nhiêu pod sẽ có bấy nhiêu pvc tương ứng
            ![alt text](../img/2.webp)
            2. Điều gì xảy ra khi ta xóa một pod -> statefulSet sẽ tạo ra một pod y nguyên cái pod xóa đi (stable network identity, stable indentity) đảm bảo không cần tạo ra một pvc mới(đảm bảo tính toàn vẹn dữ liệu):
            ![alt text](../img/3.webp)
        - Node: 
            1. Statefulset theo đúng tên của nó thích hợp triển khai các stateful app
    - Deamonset: 
        - Tổng quát: 
            1. DaemonSets là một controller đảm bảo rằng Pod của bạn sẽ được chạy trên tất cả các node trong cụm. Và nếu một node được thêm/xoá khỏi cụm thì DaemonSets cũng sẽ tự động thêm/xoá Pod.
            2. Một số trường hợp sử dụng điển hình DaemonSets là chạy các ứng dụng cấp cụm như:
                - Monitoring Exporters: 
                - Logs Collection Daemon
            3. Khi bạn sử dụng DaemonSets, nó sẽ triển khai các Pod bằng số lượng node. Tuy nhiên, về mặt hoạt động, nó sẽ hoạt động tương tự như một Deployment, tức là tất cả các Pod cũng sẽ cùng chia sẻ một Persistent Volume.
        - PVC: 
            1. Giống như Deployment tất cả các pod của Deamonset đều sử dụng chung một Volume.
        - Note: 
            1. DaemonSets sẽ không chạy trên các node có một taint (ví dụ: Master). Bạn sẽ phải chỉ định toleration cho nó trên Pod. Taints ở trong Kubernetes là một cách để yêu cầu các node loại trừ một Pod, tức là không cho phép Pod nào được chạy trên node này trừ khi Pod được chỉ định một toleration matching với taint
>> Ở trên ta có đề cập đến stateful app và stateless app. Vậy chúng là gì?:
    - Ứng dụng có thể được chia thành 2 loại là stateful application và stateless application. 
    - Stateless không lưu trạng thái xử lý trước đó, mọi request tới đều được xử lý như một yêu cầu hoàn toàn mới, không liên quan gì tới các xử lý trước đó.
    - Stateful thường thấy như các loại database (MySQL, ElasticSearch...) là các ứng dụng mà lưu trữ dữ liệu mà nó xử lý để theo dõi. Các dữ liệu này thường được lưu ở các hệ thống lưu trữ
    - Example: 
        - Command line app, nó không cần phải lưu trữ dữ liệu gì cả, tất cả những gì nó cần là xuất ra kết quả và không cần phải lưu lại kết quả đó. Những đặc tính của stateless app sẽ giúp nó dễ dàng scale hơn.
        - Ta có một trang web nodejs. Mỗi khi có request tới, nó thực hiện các nghiệp vụ của nó và lưu trạng thái vào Database(chứ bản thân cái app nó không lưu thông tin). Khi có yêu cầu sửa/xóa dữ liệu thì nó đơn giản là forward yêu cầu đó để xử lý trên database, bản thân nó không lưu dữ liệu. Bản thân nó không quan tâm tới các xử lý trước đó của nó ==> Đây là stateless app.   
2.  **- Question:** Quy trình tạo ra pod trong kubernetes?

    **- Answer:** 

    - Giả sử ta tạo ra một pod nginx. Quy trình pod được tạo ra.
    - kubectl --> api-server --> etcd: kubectl sẽ kết nối tới kube api-server và nói với kube api-server rằng tôi muốn tạo một Pod mới có tên là nginx. Lúc này kube api-server đã nhận thông tin yêu cầu, và việc tiếp theo nó sẽ thực hiện ghi thông tin yêu cầu đó vào etcd. Bạn có thể hiểu giống như bạn đang order một món ăn và api-server như một người quản lý nhận thông tin order và ghi vào giấy vậy. Khi ghi dữ liệu thành công vào etcd, etcd sẽ trả lời api-server và api-server trả về kết quả cho kubectl rằng pod đã được tạo (Pod created). Thực tế tại thời điểm này chưa có Pod nào được tạo cả.
    - scheduler --> api-server: Tiếp đến sẽ tới nhiệm vụ của Scheduler. Scheduler sẽ định kỳ hỏi lại api-server rằng "Hey, có yêu cầu gì mới cần thực hiện không?" và api-server sẽ trả lời Scheduler rằng có một request tạo mới một Pod tên là nginx, hãy lên lịch thực hiện nó đi. Scheduler lúc này sẽ thực hiện kiểm tra tất cả các node đang sẵn sàng và chọn ra một node tối ưu nhất (ví dụ node1) có thể chạy Pod trên và trả kết quả về cho api-server.
    - api-server --> etcd: Khi nhận được kết quả của Scheduler, api-server sẽ ghi thông tin vào etcd, hiểu rằng Pod nginx sẽ cần được tạo trên node1.
    - kubelet --> api-server: kubelet định kỳ kết nối với api-server để cập nhật trạng thái node mà nó đang quản lý, trạng thái các Pod đang chạy trên node đó cũng như nhận các yêu cầu mới từ api-server. Hiểu đơn giản thì kubelet trao đổi với api-server 2 câu: "Hey api-server tao đang chạy 5 pod và tất cả đều đang running ok không có vấn đề gì cả, tao cũng đang sống khỏe" "Mày có việc gì mới cho tao không?" Lúc này api-server trả lời "Có, tao cần mày chạy một Pod mới với thông tin như thế này".
    - kubelet --> CRI: kubelet đã nhận thông tin từ api-server, nó làm việc với CRI (CRI là viết tắt của cụm từ Container Runtime Interface đảm nhiệm vai trò duy trì hoạt động của container) để tạo một Pod mới theo yêu cầu (CRI có thể là Docker hoặc ContainerD)
    - controller manager: Giờ thì Pod đã được tạo xong, tuy nhiên lưu ý rằng trong lệnh tạo Pod ta đã set tham số --restart="Always" nghĩa là nếu Pod này vì lý do gì mà bị down thì cần phải tạo một Pod khác thay thế. Vậy làm sao để làm được việc đó? Câu trả lời là controller manager. Controller định kỳ sẽ gọi api-server để biết trạng thái hiện tại (current state) và trạng thái mong muốn (desired state). Trạng thái mong muốn là có 1 Pod nginx chạy trên node1, còn hiện tại thì không có Pod nginx nào đang chạy --> Controller Manager sẽ yêu cầu tạo lại Pod nginx để đảm bảo trạng thái hiện tại phải giống với trạng thái mong muốn.

Controller định kỳ sẽ gọi api-server để biết trạng thái hiện tại (current state) và trạng thái mong muốn (desired state). Trạng thái mong muốn là có 1 Pod nginx chạy trên node1, còn hiện tại thì không có Pod nginx nào đang chạy --> Controller Manager sẽ yêu cầu tạo lại Pod nginx để đảm bảo trạng thái hiện tại phải giống với trạng thái mong muốn.

3. **- Question:** Các loại service trong kubernetes. Sự khác nhau giữa service thường và Headless service.

    **- Answer:** 
    - Hiện tại kubernetes cung cấp 4 loại service: ClusterIP, NodePort, LoadBalancer, ExternalName.
    - ClusterIP: ClusterIP là một loại service chỉ cho phép truy cập bên trong cluster. Nghĩa là, các thành phần trong cùng một cluster có thể trao đổi thông tin với nhau, nhưng các thành phần bên ngoài cụm không thể giao tiếp được.ClusterIP là loại service mặc định trong K8s.
    ![alt text](../img/clusterIP.png)
    - NodePort: NodePort là một loại service trong k8s cho phép truy cập tới các thành phần từ bên ngoài cụm Kubernetes thông qua một cổng cụ thể trên mỗi Node. nodePort: là cổng được sử dụng để truy cập các pod trong kubernetes. Cổng này được chọn ngẫu nhiên trong phạm vi 30000-32767.
    - LoadBalancer: LoadBalancer là dịch vụ cung cấp khả năng cân bằng tải và khả năng truy cập từ bên ngoài cụm Kubernetes thông qua một địa chỉ IP public.  LoadBalancer sử dụng một địa chỉ IP public được cung cấp bởi nhà cung cấp dịch vụ cloud (cloud provider) để truy cập các Pod thuộc service.
    ![alt text](../img/5.jpg)
    - **Tất cả các service trên khi khởi tạo sẽ có một IP riêng**. Nhưng đối với Headless service thì bản thân nó sẽ không có IP ( trạng thái sẽ là None).
    ![alt text](../img/6.png)
    - Headless service giúp truy cập trực tiếp với pod, nó cũng không cấu hình router và các packet porwarding bằng VirtuaIP và proxy thay vào đó nó report thằng đến enpoint của thông qua DNS của cụm.
    ![alt text](../img/7.webp)
    ![alt text](../img/8.webp)
> đây cũng là lý cho mà statefulSet xử dụng headless service vì statefulSet cung cấp cho Pod một stable network identity, và vì mỗi Pod có định danh bằng index riêng nên ta có thể biết chính xác Pod nào chúng ta cần gọi tới.

4.  **- Questions**: Taint và toleration trong kubernetes. Cách sử dụng của chúng.

    **- Answer:** 
    - Có thể hiểu đơn giản thì Taint là cái ổ khóa còn toleration là cái chìa khóa. Để deploy một pod trên đó thì bạn phải có cái chìa khóa mở cái ổ khóa của node
    - Để check taint của node có thể dùng lệnh sau: k describe no <tên node> | grep Taints
    - Taint có dạng như sau: key=value:effect (các effect như NoSchedule, NoExecute). Một node có thể có nhiều taint
    - tolerations được khai báo ở spec.tolerations: sẽ có dạng: 
        > tolerations:

            - key: "key1"
              operator: "Equal"
              value: "value1"
              effect: "NoExecute"
    - Ở đây lưu lý ta có 2 toán tử (operator) chính là Equal: phải có cả value and effect. khi sử dụng Exists thì chỉ cần value or effect.

5.  **- Questions**: Kubernetes là gì?

    **- Answer:** 
        - Kubernetes là gì? Đây là một nền tảng mã nguồn mở, giúp bạn có thể tự động hóa việc quản lý và triển khai ứng dụng dưới dạng container (Container orchestration engine) một cách dễ dàng. Khái niệm container được đề cập ở phần Docker

6.  **- Question:** Các thành phần chính trong kubernetes? 

    **- Answer:** 
    - Kubernetes gồm 2 thành phần chính: 
        + Control Plane Components:
            1. kube-api-server
            2. etcd: Là một cơ sở dữ liệu dạng key-value có tính khả dụng và đồng nhất cao. Etcd là nơi K8S lưu trữ toàn bộ các thông tin cấu hình của hệ thống
            3. kube-scheduler:  Đây là service mặc định của K8S làm nhiệm vụ phân phối Pod sẽ được chạy trên node nào. Mỗi Container bên trong Pod có thể có những yêu cầu khác nhau, hoặc ngay các Pod cũng có yêu cầu khác nhau. Do đó nhiệm vụ của Scheduler là tìm kiếm các node thỏa mãn các điều kiện trên và lựa chọn node tối ưu nhất để chạy. Tron trường hợp không có node nào thỏa mãn các điều kiện đặt ra thì Pod sẽ ở trạng thái chưa được lên lịch thực hiện cho tới khi Scheduler tìm được node phù hợp.
            4. kube-controler-manager
        + Node Components:
            1. kubelet
            2. kube-proxy
            3. container runtime
+ Vai trò và cách hoạt động của kube-proxy:
 **cách check mode kube-proxy: ssh vào master node và chạy lệnh:** 
 > curl -v localhost:10249/proxyMode

    - kube-proxy là một network proxy chạy trên mỗi node trong cluster, thực hiện một phần Kubernetes Service.kube-proxy duy trình network rules trên các node. Những network rules này cho phép kết nối mạng đến các pods từ trong hoặc ngoài cluster.Kube-proxy sử dụng lớp packet filtering của hệ điều hành nếu có sẵn. Nếu không thì kube-proxy sẽ tự điều hướng network traffic. 
    - Vai trò cụ thể của kube-proxy: Quay lại kiến thức cũ pod là thành phần "nhỏ nhất" trong k8s việc tạo ra, xóa một pod là một điều hết sức bình thường, mỗi khi một pod mới được tạo nó sẽ có địa chỉ IP riêng -> rõ ràng IP của pod là một trường "không lâu dài" vì vậy service sinh ra và giải quyết nhược điểm đó. Service sẽ cung cấp một stabe IP và stabe DNS cho các pods -> Điều này cho phép các ứng dụng khác giao tiếp với các nhóm bằng cách sử dụng một địa chỉ nhất quán, ngay cả khi bản thân các pod đó đã bị xóa và được tạo lại. Để mapping (ánh xạ) Service-to-pod hoạt động ổn định thì phải liên tục ánh xạ(Re-mapping liên tục giữa Service-to-pod) đấy chính xác là điều mà kube-proxy làm. Kube-proxy giúp Service ánh xạ đên các pods bằng cách duy trì bảng định tuyến mạng ánh xạ(maintaining a network routing table that maps) các IP address của Service tới IP address của các pods thuộc về(dựa và label từ đó Service biết enpoint của ) Service. Khi nhận yêu cầu nào đó gửi tới Service, kube-proxy sử dụng ánh xạ này để chuyển tiếp(forward) yêu cầu đến Pods của Service đó.
    - How to Kube-proxy work:
        - Sau khi Kube-proxy được cài đặt, nó sẽ authenticates bởi the API server. Khi một new Service hoặc new enpoint được thêm hoặc xóa, API server thông báo những thay đổi này tới Kube-Proxy.
        - Kube-Proxy sau đó apply những thay đổi này rules NAT bên trong node. Các rules NAT này chỉ đơn giản là ánh xạ IP Service -> IP Pod. Khi một yêu cầu được gửi đến một Service, nó sẽ được chuyển hướng(redirect) đến backend của Pod dựa trên các rules.
        - Để hiểu rõ hơn ta xét một ví dụ sau:
            + Giả sử ta có một Service (type: clusterIP) **SVC01**. Khi **SVC01** được tạo API server sẽ kiểm tra các Pod nào sẽ được liên kết với Service **SVC01** thông qua trường "label(của pod)" và "label selector(của **SVC01**)"
            + Giả sử ta có thêm 2 pod lần lượt là: Pod01 và Pod02. API server tạo ra một ababstraction gọi là endpoint (enpoint sẽ đại diện cho IP của các pod)-> HIện tại **SVC01** có hai enpoint của hai pod Pod01 và Pod02 ta tạm gọi nó sẽ là **EP01** và **EP02**
            ![alt text](../img/9.png)
            ![alt text](../img/10.png)
            ![alt text](../img/11.png)
            + Muốn ánh xạ(mapping) implemented network khi truy cập đến IP của SVC01 có thể được chuyển tiếp(redirect) đến **EP01** hoặc **EP02**.Để đạt được điều đó,  API server quảng thông tin ánh xạ mới tới kube-proxy trên mỗi node, sau đó áp dụng ánh xạ đó làm internal rules(rule nội bộ).
            ![alt text](../img/12.png)
            ![alt text](../img/13.png)
            - Hiện tại lưu lượng truy cập(traffic destined ) IP SVC01 sẽ tuân rule DNAT. Rule DNat này sẽ chuyển tiếp traffic đến Pod. Hãy nhớ rằng **EP01** và **EP02** về cơ bản là IP của Pod.
    - kube-proxy Mode:
        + User-space mode
        ![alt text](../img/13.1.png)
        + IPtables mode: Đây là chế độ mặc định và được sử dụng rộng rãi nhất hiện nay. Nó cũng dựa vào tính năng của IPTables insert rules vào node. Thay vì insert rules để chuyển tiếp kết nối tới chính Kube-Proxy, chế độ này sẽ chèn trực tiếp quy tắc Service-to-Pod vào IPtables. Bằng cách này, Kube-Proxy sẽ tự giải phóng mình khỏi việc cản trở giao thông. Điều này giúp tiết kiệm độ trễ bổ sung liên quan User-space mode.Điều này thay đổi vai trò Kube-Proxy từ proxy thực tế thành chỉ là “người cài đặt” các quy tắc.Nhược điểm của chế độ này là IPtables sử dụng cách tiếp cận tuần tự khi thực hiện tra cứu bảng(độ phức tạp O(n)). Vì vậy, nó đi qua từng quy tắc trong bảng cho đến khi tìm thấy kết quả phù hợp và áp dụng quy tắc đó.Một nhược điểm khác là IPtables không hỗ trợ các thuật toán cân bằng tải.
        ![alt text](../img/14.png)
        + IpvIPVS mode
7.  **- Question:** NodePort vs Ingress vs LoadBalancer trong Kubernetes?. 

    **- Answer:**

    + NodePort Service: là một trong những cách nguyên thủy nhất đễ kết nối external traffic trực tiếp tới service của bạn. NodePort như cái tên đã ngụ ý, sẽ mở một port trên tất cả các Nodes(VMs), băt cứ traffic nào tới các node này sẽ được chuyển tiếp đến service.
    + Load Balancer: là Một LoadBalancer Service là cách thức chuẩn đễ expose service với Internet Nếu bạn muốn trực tiếp expose một service, đây là phương thức mặc định. Tất các các traffic trên port bạn đã chỉ định sẽ được chuyển tiếp tới service. Sẽ không có filter, routing, etc. Do đó bạn có thể gửi hầu hết các loại traffic đến nó, như HTTP, TCP, UDP, WebSockets, gRPC..
    + Kubernetes Ingress:
        - Vì sao sử dụng ingress:
        - Giới thiệu:
            - Kubernetes Ingress là một tài nguyên quan trọng trong hệ thống Kubernetes, được sử dụng để quản lý và kiểm soát việc truy cập vào các dịch vụ (Services) trong một cụm Kubernetes từ bên ngoài. Ingress cho phép bạn quản lý các luồng lưu lượng truy cập từ internet hoặc các nguồn khác và định tuyến chúng đến các dịch vụ hoặc ứng dụng cụ thể bên trong cụm Kubernetes.
            - Ingress mở và phân luồng các kết nối HTTP và HTTPS từ bên ngoài k8s cluster vào các services bên trong cluster. Việc phân luồng dữ liệu này được quản lý bởi các "rule" được định nghĩa ở các tài nguyên Ingress trên k8s. Việc thực thi phân luồng dữ liệu được thực hiện bởi Ingress Controller, là một opensource cài đặt trên K8S. Nhiệm vụ của Ingress Controller là nạp các thông tin của các Ingress Resource để thực hiện phân luồng.
        - Cơ chế hoạt động:
            - Tạo tài nguyên Ingress: Đầu tiên, bạn tạo một tài nguyên Ingress trong cụm Kubernetes. Tài nguyên Ingress chứa các quy tắc định tuyến lưu lượng truy cập.
            - Ingress Controller: Là thành phần điều khiển chính làm nhiệm vụ điều hướng các request tới các service bên trong k8s. Thường thì Ingress Controller được cài đặt trên K8S và được expose ra ngoài dưới dạng NodePort.
            - Ingress Rule: Là một tài nguyên trên K8S. Nó chứa nội dung khai báo rule để điều hướng từ một request tới một service cụ thể trên trong K8S.
            - Có nhiều Ingress Controller từ các nhà phát triển khác bạn có thể lựa chọn để cài đặt. Ngoài ra trên k8s cũng hỗ trợ cài đặt nhiều Ingress Controller tùy nhu cầu sử dụng.
