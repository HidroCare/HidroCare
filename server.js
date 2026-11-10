/**
 * V A R I Á V E I S sql supabase -
 * pacientes:
 *      nome,
 *      idade,
 *      sexo,
 *      massa numeric,
 *      motivo internacao;
 * registros:
 *      valor numeric,
 *      submissao_id,
 *      tipo,
 *      descricao,
 *      correto
 */
require("dotenv").config();

const express = require("express");
const authRoutes = require("./routes/authRoutes");

const app = express();

app.use(express.json());

// Rota principal
app.get("/", (req, res) => {
    res.json({
        mensagem: "Servidor HidroCare funcionando!"
    });
});

// Rotas de autenticação
app.use("/auth", authRoutes);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    
    console.log(`Servidor rodando na porta ${PORT}`);
});