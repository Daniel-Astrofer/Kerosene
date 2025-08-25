import android.util.Log
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.Body
import retrofit2.http.POST

// Importe as suas classes de dados e a interface da API
data class Usuario(val nome: String, val pass: String, val fingertip: String)

interface MyApi {
    @POST("/api/user")
    fun criarUsuario(@Body usuario: Usuario): Call<Usuario>
}

// Uma função de exemplo para fazer a chamada da API.
// Você pode colocar isso em uma classe de serviço ou ViewModel.
fun criarNovoUsuario(nome:String, pass : String , fingertip:String) {
    // 1. Configurar o Retrofit.
    // Lembre-se de substituir a BASE_URL pelo endereço da sua API.
    val retrofit = Retrofit.Builder()
        .baseUrl("http://192.168.3.30:8080/") // EX: https://api.exemplo.com/
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    // 2. Criar uma instância da sua interface de API
    val apiService = retrofit.create(MyApi::class.java)

    // 3. Criar o objeto de usuário que será enviado no corpo da requisição
    val novoUsuario = Usuario(
        nome = nome,
        pass = pass,
        fingertip = fingertip
    )

    // 4. Fazer a chamada assíncrona para a API
    // O método `enqueue` executa a chamada em segundo plano para não travar a UI
    apiService.criarUsuario(novoUsuario).enqueue(object : Callback<Usuario> {

        // Este método é chamado quando a resposta da API é recebida (sucesso ou falha)
        override fun onResponse(call: Call<Usuario>, response: Response<Usuario>) {
            if (response.isSuccessful) {
                // A requisição foi bem-sucedida (código 2xx)
                val usuarioCriado = response.body()
                Log.d("API_CALL", "Usuário criado com sucesso! ID: ${usuarioCriado?.nome}")
                // Você pode usar o objeto `usuarioCriado` aqui, se a API retornar dados.
            } else {
                // A requisição falhou, mas a resposta foi recebida (código 4xx, 5xx, etc.)
                Log.e("API_CALL", "Falha na requisição. Código de erro: ${response.code()}")
                // Você pode ler o corpo do erro para mais detalhes, se a API fornecer.
                val errorBody = response.errorBody()?.string()
                Log.e("API_CALL", "Corpo do erro: $errorBody")
            }
        }

        // Este método é chamado se houver um erro na rede ou na preparação da requisição
        override fun onFailure(call: Call<Usuario>, t: Throwable) {
            // Exibe a mensagem de erro no logcat
            Log.e("API_CALL", "Erro na chamada da API: ${t.message}")
            t.printStackTrace()
        }
    })
}

// Exemplo de como chamar a função `criarNovoUsuario`
// Esta parte não precisa estar no mesmo arquivo, mas mostra o uso.

