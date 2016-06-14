#!/bin/bash

function func2
{
    if [[ -z $aa ]]; then
        echo "xx"
    else
        echo $aa
    fi
}
function func1
{
    aa="kk"
    echo $aa
    func2
}


func1
