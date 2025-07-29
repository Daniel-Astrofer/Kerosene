
package com.example.again

import android.annotation.SuppressLint
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement


import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer


import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.input.rememberTextFieldState
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.again.ui.theme.AgainTheme





@Composable
fun LoginScreen(navController: NavController, viewModel: oi = viewModel()){

    Column(modifier = Modifier
        .fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ){
        BoxLogin(navController,viewModel)
    }





}
@Composable
fun BoxLogin(navController: NavController, viewModel: oi = viewModel()){
    var rememberText by remember{mutableStateOf("")}
    var rememberPass by remember{mutableStateOf("")}
    val nome  by viewModel.name.collectAsState()


    Column(horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = Modifier
            .background(color = Color.LightGray)
            .size(300.dp)
    ){

        Text("Login")

        TextField(value= rememberText , keyboardActions = KeyboardActions.Default, onValueChange = { rememberText = it
            viewModel.set(rememberText)},label = { Text("Email") })

        Spacer(Modifier.padding(23.dp))

        TextField(value= rememberPass, onValueChange = { rememberPass = it},label = { Text("Senha") })

        if ( (Verify(rememberText,rememberPass)) == true ){Text("Perfeito")
            Button(onClick = {navController.navigate("second")}) { Text("Entrar") }}





    }





}

