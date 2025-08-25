package com.example.again.main

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.background
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
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.navigation.NavController
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.sharp.Menu
import androidx.compose.material.icons.sharp.Settings
import androidx.compose.material.icons.twotone.AccountCircle
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.sp
import androidx.navigation.compose.rememberNavController
import com.example.again.R


@Composable
fun Screen(navController: NavController) {


    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val size = this
        Column {
            EarthRender()
            MidBar()
            ClickableMenu()
        }
        TopBar(navController)
    }



}

@Composable
fun TopBar(navController: NavController){
    var optionsClick by remember { mutableStateOf(false) }

    BoxWithConstraints(modifier = Modifier
        .fillMaxWidth()
        ,
        contentAlignment = Alignment.TopCenter) {

        val size = this


            if (!optionsClick){

                Row(modifier = Modifier
                    .width(size.maxWidth * 0.75f)
                    .clip(RoundedCornerShape(bottomStart = 50.dp, bottomEnd = 50.dp))
                    .background(color=Color.Black),
                    horizontalArrangement = Arrangement.Center){

                    IconButton(onClick = {
                        optionsClick = true } ) {
                        Icon(Icons.Sharp.Menu, tint = Color.White, contentDescription = "Menu" )
                    }

                    Spacer(modifier = Modifier.padding(end = size.maxWidth * 0.15f))

                    IconButton(onClick = { navController.navigate("main") }) {
                        Icon(Icons.TwoTone.AccountCircle, contentDescription = "Perfil", tint =Color.White)
                    }

                    Spacer(modifier = Modifier.padding(start = size.maxWidth * 0.15f))

                    IconButton(onClick ={}) {
                        Icon(Icons.Sharp.Settings,contentDescription = "Configurações", tint = Color.White)

                    }


                }
            }
    }
}


@Composable
fun EarthRender(){

    val saldo : Double = 1000000.00

    BoxWithConstraints(modifier = Modifier
        .fillMaxWidth()
        .aspectRatio(1f)) {

        val size = this


        Box(contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(size.maxHeight * 1f)){
            Image(
                painter = painterResource(id = R.drawable.olaaa),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
            Earth()
            Text(
                text = "R\$ ${"%,.2f".format(saldo)}",
                color = Color(0xFF4CAF50),
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace,
                textAlign = TextAlign.Center,
                letterSpacing = 1.sp
            )
        }


    }


}

@Composable
fun MidBar(){


    Column(modifier = Modifier.background(Color.Black).fillMaxWidth().height(70.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(Icons.Sharp.Menu, contentDescription = "Menu", tint = Color.White, modifier = Modifier.size(18 .dp))
    }




}

@Composable
fun ClickableMenu(){

    BoxWithConstraints(modifier = Modifier
        .fillMaxSize()
        .aspectRatio(1f)
        .background(Color.Black),
        contentAlignment = Alignment.Center) {
        val size = this


        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {


            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)){

                Box(modifier = Modifier.size(size.maxWidth * 0.45f).clip(RoundedCornerShape(30.dp)).background(color = Color.DarkGray), contentAlignment = Alignment.Center){

                    IconButton(onClick = {}) {
                        Icon(Icons.Filled.Place ,contentDescription = "Miner",tint = Color.White, modifier = Modifier.size(100.dp))

                    }
                    Text("Krinse",modifier = Modifier.align(Alignment.BottomEnd).padding(end = 20.dp) )

                }

                Box(modifier = Modifier.size(size.maxWidth * 0.45f).clip(RoundedCornerShape(30.dp)).background(color = Color.DarkGray), contentAlignment = Alignment.Center){

                    IconButton(onClick = {}) {
                        Icon(Icons.Filled.Info, contentDescription = "Krinse",modifier = Modifier.size(100.dp),tint = Color.White)

                    }

                }

            }

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)){

                Box(contentAlignment = Alignment.Center, modifier = Modifier.size(size.maxWidth * 0.45f).clip(RoundedCornerShape(30.dp)).background(color = Color.DarkGray)){
                    IconButton(onClick = {}) {

                        Icon(Icons.Default.Search, contentDescription = "Buy", modifier = Modifier.size(100.dp), tint = Color.White)

                    }
                }

                Box(contentAlignment = Alignment.Center, modifier = Modifier.size(size.maxWidth * 0.45f).clip(RoundedCornerShape(30.dp)).background(color = Color.DarkGray)){
                    IconButton(onClick = {}) {

                        Icon(Icons.Default.Menu , contentDescription = "Buy", modifier = Modifier.size(100.dp),tint = Color.White)

                    }
                }
            }
        }
    }

}

@Composable
fun Earth() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .drawBehind {
                val brush = Brush.horizontalGradient(listOf(Color.Blue,Color.Black))
                val arcDiameter = size.width * 1.8f
                drawArc(
                    brush = brush,
                    startAngle = -90f,
                    sweepAngle = 90f,
                    useCenter = true,
                    topLeft = Offset(x = -arcDiameter / 2f, y = size.height - (arcDiameter / 2f)),
                    size = Size(arcDiameter, arcDiameter) ) } )
}

@Preview
@Composable
fun Screen() {

    val navController = rememberNavController()
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val size = this
        Column {
            EarthRender()
            MidBar()
            ClickableMenu()
        }
        TopBar(navController)
    }



}


