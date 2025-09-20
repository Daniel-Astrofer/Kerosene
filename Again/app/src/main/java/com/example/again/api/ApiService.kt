package com.example.again.api

import com.example.again.api.model.Usuario
import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path

interface ApiService {

    @POST("usuarios/create")
    fun createUser( @Body usuario: Usuario): Call<Usuario>

    @GET("usuarios/authenticate/{username}")
    fun findbyname(@Path("username") username:String): Call<Usuario>

}