package com.example.again.login
import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import java.util.List
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.Callback
import retrofit2.Response

data class Usuario(val nome: String, val pass: String,val  fingertip : String)

interface MyApi {

    @POST("/api/users")
    fun criarUsuario(@Body usuario: Usuario): Call<Usuario>


}
