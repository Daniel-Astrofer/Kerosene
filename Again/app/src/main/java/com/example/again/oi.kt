package com.example.again

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel

class oi: ViewModel(){
    var name by mutableStateOf("")
    private set

    fun set(new : String){
        name = new
    }


}