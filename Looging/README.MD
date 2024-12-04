# `Set up EFK`

* Note 
    -   run in elastic **elasticsearch-setup-passwords** to take all password. Remember note in your text. The *secret* of kibana is the **kibana password** 
    -   ```
        - name: ELASTICSEARCH_HOSTS
        value: '["http://elasticsearch-master-0.elasticsearch-master-headless:9200","http://elasticsearch-master-1.elasticsearch-master-headless:9200"]'
        ```
    - There are two ways for kibana to connect to elasticsearch:
      - using **headless service** : *Podname*.*headless-service*:9200
      - using **service**: *Servicename*:9200
