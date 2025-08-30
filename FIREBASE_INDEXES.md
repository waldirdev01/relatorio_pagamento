# 🔥 Índices Necessários no Firebase Firestore

## 🎯 **INSTRUÇÕES RÁPIDAS:**
1. **Execute o app** → Navegue pelas telas
2. **Veja o erro no console** com link do Firebase
3. **Clique no link** → Firebase cria automaticamente
4. **Aguarde 5-10 minutos** para ativação

---

## 📋 **Índices que serão necessários:**

### 1. **Coleção: `contratos`**
**Query**: `where(regionalId).where(ativo).orderBy(nome)`
```
Fields:
- regionalId (Ascending)
- ativo (Ascending) 
- nome (Ascending)
```

### 2. **Coleção: `itinerarios`**  
**Query**: `where(regionalId).where(turno).orderBy(itinerario)`
```
Fields:
- regionalId (Ascending)
- turno (Ascending)
- itinerario (Ascending)
```

### 3. **Coleção: `atividades_extracurriculares`**
**Query**: `where(regionalId).orderBy(dataCriacao, descending)`
```
Fields:
- regionalId (Ascending)
- dataCriacao (Descending)
```

### 4. **Coleção: `atividades_extracurriculares`** (para contratos)
**Query**: `where(contratoId).orderBy(dataCriacao, descending)`
```
Fields:
- contratoId (Ascending)
- dataCriacao (Descending)
```

---

## 🔗 **Como usar os links automáticos:**

1. **Execute o app Flutter**
2. **Navegue para**: Contratos, Itinerários, Atividades
3. **No console**, procure por: `🔗 ERRO COMPLETO PARA CLICAR NO LINK:`
4. **Clique no link** que aparece (formato: `https://console.firebase.google.com/...`)
5. **Aguarde criação** (5-10 minutos)

---

## 📁 **Arquivo firestore.indexes.json completo:**

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": [
      {
        "collectionGroup": "contratos",
        "queryScope": "COLLECTION",
        "fields": [
          {"fieldPath": "regionalId", "order": "ASCENDING"},
          {"fieldPath": "ativo", "order": "ASCENDING"},
          {"fieldPath": "nome", "order": "ASCENDING"}
        ]
      },
      {
        "collectionGroup": "itinerarios", 
        "queryScope": "COLLECTION",
        "fields": [
          {"fieldPath": "regionalId", "order": "ASCENDING"},
          {"fieldPath": "turno", "order": "ASCENDING"},
          {"fieldPath": "itinerario", "order": "ASCENDING"}
        ]
      },
      {
        "collectionGroup": "atividades_extracurriculares",
        "queryScope": "COLLECTION", 
        "fields": [
          {"fieldPath": "regionalId", "order": "ASCENDING"},
          {"fieldPath": "dataCriacao", "order": "DESCENDING"}
        ]
      },
      {
        "collectionGroup": "atividades_extracurriculares",
        "queryScope": "COLLECTION",
        "fields": [
          {"fieldPath": "contratoId", "order": "ASCENDING"},
          {"fieldPath": "dataCriacao", "order": "DESCENDING"}
        ]
      }
    ]
  }
}
```

---

## ⚠️ **Problemas comuns:**

- **Conta errada**: Troque `/u/0/` por `/u/1/` na URL
- **Projeto errado**: Verifique se está no `relatorio-pagamento-2e5c6`
- **Demora**: Índices levam 5-10 minutos para ativar

**✅ Quando funcionará**: App parará de dar erro e as listas vão aparecer ordenadas!