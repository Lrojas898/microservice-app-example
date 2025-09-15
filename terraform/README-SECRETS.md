# Configuración de Secretos para Terraform

## Solución Implementada: Azure Key Vault

Se ha implementado Azure Key Vault para manejar las contraseñas de PostgreSQL de forma segura. Las contraseñas se generan automáticamente si no se proporcionan.

## Configuración Requerida

### 1. Secretos de GitHub Actions

Configura los siguientes secretos en tu repositorio de GitHub:

```
ARM_CLIENT_ID
ARM_CLIENT_SECRET  
ARM_TENANT_ID
ARM_SUBSCRIPTION_ID
```

### 2. Variables de Terraform (Opcional)

Si quieres usar contraseñas específicas, crea un archivo `terraform.tfvars`:

```hcl
# Contraseñas personalizadas (opcional)
postgres_auth_password = "tu_contraseña_auth"
postgres_users_password = "tu_contraseña_users" 
postgres_todos_password = "tu_contraseña_todos"
```

**Nota**: Si no proporcionas contraseñas, se generarán automáticamente y se almacenarán en Azure Key Vault.

## Cómo Funciona

1. **Generación Automática**: Si no se proporcionan contraseñas, Terraform genera contraseñas aleatorias seguras usando el provider `random`.

2. **Almacenamiento Seguro**: Las contraseñas se almacenan en Azure Key Vault con nombres descriptivos:
   - `postgres-auth-password`
   - `postgres-users-password`
   - `postgres-todos-password`

3. **Acceso Controlado**: Solo el usuario/entidad de servicio que ejecuta Terraform puede acceder a los secretos.

## Recuperar Contraseñas

Después del despliegue, puedes recuperar las contraseñas de dos formas:

### Opción 1: Desde Terraform Output
```bash
terraform output postgres_auth_password
terraform output postgres_users_password
terraform output postgres_todos_password
```

### Opción 2: Desde Azure Key Vault
```bash
az keyvault secret show --vault-name microservice-kv --name postgres-auth-password --query value -o tsv
az keyvault secret show --vault-name microservice-kv --name postgres-users-password --query value -o tsv
az keyvault secret show --vault-name microservice-kv --name postgres-todos-password --query value -o tsv
```

## Alternativas Consideradas

### Solución 2: Variables de Entorno (Más Simple)
```bash
export TF_VAR_postgres_auth_password="tu_contraseña"
export TF_VAR_postgres_users_password="tu_contraseña"
export TF_VAR_postgres_todos_password="tu_contraseña"
```

### Solución 3: Archivo de Variables Local
Crear `terraform.tfvars` con las contraseñas (no recomendado para producción).

## Seguridad

- ✅ Las contraseñas se marcan como `sensitive = true`
- ✅ Se almacenan en Azure Key Vault (encriptado)
- ✅ Acceso controlado por Azure AD
- ✅ No se muestran en logs de Terraform
- ✅ Rotación automática posible

## Próximos Pasos

1. Configura los secretos de Azure en GitHub Actions
2. Ejecuta el pipeline - las contraseñas se generarán automáticamente
3. Recupera las contraseñas desde Key Vault o outputs de Terraform
4. Configura tus aplicaciones con las contraseñas obtenidas
