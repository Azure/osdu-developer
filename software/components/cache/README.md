# Instructions


```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: redis-client
spec:
  containers:
  - name: redis-client
    image: redis:6.2.5-alpine
    command: ["/bin/sh", "-c", "sleep 3600"]
EOF

kubectl exec -it redis-client -- sh

redis-cli -h $REDIS_HOSTNAME -p 6380 -a $REDIS_PASSWORD --tls
```