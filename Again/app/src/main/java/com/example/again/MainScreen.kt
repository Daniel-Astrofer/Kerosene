package com.example.again

import android.annotation.SuppressLint
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Face
import androidx.compose.material.icons.twotone.AccountBox
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.compose.material3.*
import androidx.compose.foundation.layout.*
import androidx.navigation.Navigator

@SuppressLint("UnusedMaterial3ScaffoldPaddingParameter")
@Composable
fun Main(navController:NavController){
    Button(onClick = {navController.navigate("second")}) { Text("Login") }
    Scaffold(
        topBar = {TopBar()},
        bottomBar = { BottomBar() } ,
        modifier = Modifier
            .padding(top= 25.dp)

    ) {

        Box{

        Middle(navController)


    } }




}
//hello GITHUBsadasdaadaasdadsadadadada
@Composable
fun TopBar(){
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(color = Color.Cyan)
            .height(80.dp)
    ) {
        Row{
            IconButton(onClick = {}) {
                Icon(Icons.TwoTone.AccountBox, contentDescription = "Perfil")
            }


            IconButton(onClick = {}) {
                Icon(Icons.Default.Face, contentDescription = "Face")
            }
        }
        Text("Olá, Astrofer")
    }
}

@Composable
fun Middle(navController: NavController){

    Column (modifier = Modifier
        .fillMaxSize()
        .background(color = Color.Red),
        horizontalAlignment = Alignment.CenterHorizontally){
        BoxOne()
        BoxTwo()
        Button(onClick = {navController.navigate("second")}) { Text("Login") }

    }



}


@Composable
fun BottomBar(){

    Row (modifier = Modifier
        .height(40.dp)
        .fillMaxWidth()
        .background(color = Color.Blue)
    ){ Text("Algo") }



}


@Composable
fun BoxOne(){

    Column(modifier = Modifier
        .fillMaxWidth()
        .height(200.dp)
        .background(color= Color.Green),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally)

    { Text("SALDO : R$1.200,00") }

}

@Composable
fun BoxTwo(){


    Column(modifier = Modifier
        .fillMaxWidth()
        .background(color= Color.Yellow)
        .height(300.dp),
        horizontalAlignment = Alignment.CenterHorizontally)

    { Text("Caixinhas") }



}