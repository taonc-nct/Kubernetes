- Còn alert cho cụm thanos
- test lại hashring khi sử dụng nhiều receive.
- Đẩy dữ liệu promethues-> thanos (promethues-promethues.yaml)
  remoteWrite:
  - url: http://release-name-thanos-receive.thanos.svc.cluster.local:19291/api/v1/receive
    queueConfig:
      maxSamplesPerSend: 500
      maxShards: 10
      capacity: 5000
      batchSendDeadline: 5s
      minBackoff: 100ms
      maxBackoff: 5s