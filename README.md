**To Build:**

```
docker build -t c7/lamp .
```

**To Run:**

```
docker run -dt -p8080:80 --name=c7-lamp c7/lamp
```

**To Enter:**

```
docker exec -it c7-lamp bash
```
