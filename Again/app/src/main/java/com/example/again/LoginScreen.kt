
package com.example.again

import android.annotation.SuppressLint
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement


import androidx.compose.foundation.layout.Column


import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.example.again.ui.theme.AgainTheme





@Composable
fun LoginScreen(navController: NavController){

    Column(modifier = Modifier
        .fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ){
        BoxLogin(navController)

    }





}

@Composable
fun BoxLogin(navController: NavController){

    Column(horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .background(color= Color.LightGray)
            .size(300.dp)
    ){
        Text("Login")
        Button(onClick = {navController.navigate("main")}) { Text("Voltar") }


    }




}