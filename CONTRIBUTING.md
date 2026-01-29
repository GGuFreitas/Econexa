# 📘 Padrão de Desenvolvimento do Projeto ECONEXA

Este documento define os **padrões oficiais de organização, versionamento e colaboração** do projeto **ECONEXA**. O objetivo é manter o código limpo, organizado e facilitar o trabalho em equipe, mesmo com desenvolvedores em níveis diferentes.

---

## 🎯 Objetivos deste padrão

* Evitar bagunça no repositório
* Facilitar a entrada de novos colaboradores
* Garantir histórico de código claro
* Reduzir conflitos e retrabalho
* Simular um ambiente profissional de desenvolvimento

---

## 🌳 Estrutura de Branches

Utilizamos uma estratégia **simples e eficiente**, inspirada em boas práticas do mercado.

### Branches fixas

* **main** → versão estável (produção)
* **develop** → integração das funcionalidades

> 🚫 Nunca desenvolva diretamente na `main`

---

### Branches temporárias

Criadas a partir da branch `develop`:

* `feature/nome-da-feature`
* `bugfix/nome-do-bug`
* `hotfix/nome-do-problema`

#### Exemplos

* `feature/auth-jwt`
* `feature/issue-crud`
* `feature/map-leaflet`
* `bugfix/login-null-pointer`

---

## 🔄 Fluxo de Trabalho

1. Atualizar a branch develop

```bash
git checkout develop
git pull origin develop
```

2. Criar a branch da feature

```bash
git checkout -b feature/nome-da-feature
```

3. Desenvolver a funcionalidade
4. Realizar commits seguindo o padrão
5. Abrir Pull Request para `develop`

---

## ✍️ Padrão de Commits

Utilizamos **commits semânticos**, claros e objetivos.

### Estrutura

```
tipo: descrição curta no presente
```

### Tipos permitidos

* **feat** → nova funcionalidade
* **fix** → correção de bug
* **refactor** → melhoria sem alterar regra de negócio
* **docs** → documentação
* **test** → testes
* **chore** → configuração, dependências, build

### Exemplos corretos

```
feat: implementa autenticação com JWT
fix: corrige erro de null no login
docs: adiciona padrão de contribuição
chore: configura docker-compose
```

🚫 Evite commits genéricos como:

```
update
final
ajustes
teste
```

---

## 🧩 Organização de Tarefas (Issues)

Utilizamos **GitHub Issues** para organizar o trabalho.

### Cada Issue deve conter:

* **Título claro**
* **Descrição objetiva**
* **Critérios de aceite**

### Exemplo

```
Título: Implementar cadastro de usuário

Descrição:
Criar endpoint de cadastro com email e senha
Senha deve ser criptografada

Critérios de aceite:
- Usuário salvo no banco
- Senha com BCrypt
- JWT retornado
```

> 📌 Regra: **1 Issue = 1 Branch**

---

## 🔀 Padrão de Pull Request

Todo Pull Request deve responder:

* O que foi feito?
* Por que foi feito?
* Como testar?

### Template de PR

```
## O que foi feito?
- Implementação do login com JWT

## Por que foi feito?
- Necessário para autenticação do sistema

## Como testar?
- POST /auth/login com credenciais válidas
```

🚫 Pull Requests com múltiplas funcionalidades não são permitidos.

---

## 🧱 Padrão de Estrutura do Backend

```text
com.econexa
├── config
├── controller
├── dto
├── entity
├── repository
├── service
├── security
├── exception
```

### Regras importantes

* Controller **não acessa repository diretamente**
* Regras de negócio ficam no **service**
* Repository apenas acessa o banco

---

## 🧠 Boas Práticas Gerais

* Commits pequenos e frequentes
* Nome de classes e métodos claros
* Código deve ser legível antes de ser inteligente
* Documentar decisões importantes no README
* Priorizar clareza ao invés de complexidade

---

## 👥 Comunicação do Time

* Dúvidas devem ser alinhadas antes de grandes mudanças
* Mudanças estruturais precisam ser discutidas
* Todos são responsáveis pela qualidade do projeto

---

## 🚀 Considerações Finais

Este padrão não existe para burocratizar, mas para **facilitar o crescimento do ECONEXA** como um projeto real, profissional e colaborativo.

Qualquer melhoria nesse padrão pode ser sugerida via Issue.

---

📌 **ECONEXA — Conectando pessoas, dados e ação socioambiental**
