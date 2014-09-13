# dns_resolver Monitoring script 

## DNS Resolver performance Monitoring

```ruby
 +time=T - Sets the timeout for a query to T seconds. The default timeout is 5 seconds. An attempt to set T to less than 1 will result in a query timeout of 1 second being applied.
 resolution=1 - Look at the below domain and try resolving it. May be one or more domain is NOT resolving.
 resolverstatus=1 - This means one or more domain resolution didnt go through primary resolver in /etc/resolv.conf. Investigate by quering to Primary..
 queryavg - This indicates the average query resolution time and the values are in Milli Seconds
 TtlLkupTime - This is total time taken to resolve all the dns domains query lookup and the values are in Seconds
```
## Contact: rameshshihora@gmail.com
