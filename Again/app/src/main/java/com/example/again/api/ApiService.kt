package com.example.again.api

import com.example.again.api.model.Usuario
import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.POST

interface ApiService {

    @POST("create")
    fun createUser( @Body usuario: Usuario): Call<Usuario>

}