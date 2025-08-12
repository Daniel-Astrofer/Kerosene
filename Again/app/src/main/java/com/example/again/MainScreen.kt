package com.example.again

import android.annotation.SuppressLint
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.navigation.NavController
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.sharp.Menu
import androidx.compose.material.icons.sharp.Settings
import androidx.compose.material.icons.twotone.AccountCircle
import androidx.compose.material.icons.twotone.Build
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.navigation.compose.rememberNavController



@SuppressLint("UnusedMaterial3ScaffoldPaddingParameter")
@Composable
fun Screen(navController:NavController){
    Scaffold(
        topBar = {TopBar(navController)},
        bottomBar = { BottomBar() } ,
        modifier = Modifier
            .fillMaxSize()
            .padding(top= 25.dp))
    {

        Column {

            Box(){
                FirstWindow()
            }

            Box(){
                Buttons()
            }


        }

    }
}

@Composable
fun TopBar(navController: NavController){

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(45.dp)
            ,horizontalAlignment = Alignment.CenterHorizontally
    ) {




            Row(modifier = Modifier.clip(RoundedCornerShape(bottomStart = 30.dp, bottomEnd = 30.dp)).background(color=Color.Black)){
                IconButton(onClick = {} ) {
                    Icon(Icons.Sharp.Menu, tint = Color.White, contentDescription = "Menu" )
                }
                Spacer(modifier = Modifier.padding(end = 110.dp))
                IconButton(onClick = { navController.navigate("main") }) {
                    Icon(Icons.TwoTone.AccountCircle, contentDescription = "Perfil", tint =Color.White)
                }
                Spacer(modifier = Modifier.padding(start = 110.dp))
                IconButton(onClick ={}) {
                    Icon(Icons.Sharp.Settings,contentDescription = "Configurações", tint = Color.White)

                }
            }
        }
    }


@Composable
fun FirstWindow(){


    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(370.dp)
            .background(color = Color.DarkGray),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally){
        Box(contentAlignment = Alignment.BottomStart){
            Earth()}

        Text("$1.000.000.000,00", fontFamily =  FontFamily.Monospace, fontWeight =  FontWeight.ExtraBold, fontStyle =  FontStyle.Italic)


    }


}

@Composable
fun Buttons(){

    Surface(modifier = Modifier.fillMaxWidth().background(color = Color.Black) ) {


        Column (){


            Row() {

                Box(modifier = Modifier.size(200.dp).border(2.dp,color = Color.DarkGray,).background(color = Color.Black), contentAlignment = Alignment.Center){

                    IconButton(onClick = {}) {
                        Icon(Icons.TwoTone.Build ,contentDescription = "Miner",tint = Color.White)

                    }

                }

                Box(modifier = Modifier.border(2.dp,color = Color.DarkGray,).background(color = Color.Black).size(200.dp), contentAlignment = Alignment.Center){

                    IconButton(onClick = {}) {
                        Icon(Icons.Default.Star, contentDescription = "Krinse",modifier = Modifier.size(100.dp),tint = Color.White)

                    }

                }

            }

            Row {

                Box(contentAlignment = Alignment.Center, modifier = Modifier.border(2.dp,color = Color.DarkGray,).size(200.dp).background(color=Color.Black)){
                    IconButton(onClick = {}) {

                        Icon(Icons.Default.Search, contentDescription = "Buy", modifier = Modifier.size(100.dp), tint = Color.White)

                    }
                }

                Box(contentAlignment = Alignment.Center, modifier = Modifier.border(2.dp,color = Color.DarkGray,).size(200.dp).background(color=Color.Black)){
                    IconButton(onClick = {}) {

                        Icon(Icons.Default.Menu , contentDescription = "Buy", modifier = Modifier.size(100.dp),tint = Color.White)

                    }
                }
            }
        }
    }
}

@Composable
fun Content(navController: NavController){

    Column (modifier = Modifier
        .fillMaxSize()
        ,
        horizontalAlignment = Alignment.CenterHorizontally){
        Box(modifier = Modifier.background(Color.Black)){

            FirstWindow()


        }

        Buttons()


    }

}


@Composable
fun BottomBar(){

    Row (modifier = Modifier
        .height(40.dp)
        .fillMaxWidth()

        .background(color = Color.DarkGray)
    ){ Text("bottom activer") }



}





@Composable
fun Earth() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(100.dp)
            .drawBehind {
                val arcDiameter = size.width * 2f
                drawArc(
                    color = Color.Blue,
                    startAngle = 180f,
                    sweepAngle = 180f,
                    useCenter = true,
                    topLeft = Offset(x = -size.width / 1f, y = -size.height),
                    size = Size(arcDiameter, arcDiameter) ) } )
}


@Preview
@SuppressLint("UnusedMaterial3ScaffoldPaddingParameter")
@Composable
fun Main(){
    val navController=rememberNavController()

    Scaffold(
        topBar = {TopBar(navController)},
        bottomBar = { BottomBar() } ,
        modifier = Modifier
            .padding(top= 25.dp)

    ) {

        Box{


            Content(navController)


        } }




}


