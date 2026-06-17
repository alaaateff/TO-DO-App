output "frontend_repository_name" {
    value = aws_ecr_repository.frontend_repo.name
}
output "frontend_repository_url" {
    value = aws_ecr_repository.frontend_repo.repository_url
}
output "backend_repository_name" {
    value = aws_ecr_repository.backend_repo.name
}
output "backend_repository_url" {
    value = aws_ecr_repository.backend_repo.repository_url
}