resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_elasticache_replication_group" "redis" {
  description = "Redis cluster for both primary and cache"
  replication_group_id          = "redis-cluster"
  engine                        = "redis"
  engine_version                = "7.1"
  node_type                     = "cache.t3.micro"
  num_cache_clusters            = 1
  parameter_group_name          = "default.redis7"
  port                          = 6379
  automatic_failover_enabled    = false
  security_group_ids            = [aws_security_group.elasticache_sg.id]
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.name

  tags = {
    Name = "RedisCluster"
  }
}
