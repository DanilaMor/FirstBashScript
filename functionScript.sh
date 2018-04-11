
#!/bin/bash
parse ()
{

    filename=$1
    str=`cat $filename | jq .results[0].name`
    str1=$str	
    j=0
{
    echo "Repository"   
    echo " "
    cat $filename | jq .results[0].repo 
    echo " "
} >> final_report 

    s=`cat $filename | jq .results[0].repo`
    echo $s 




while [ "$str1" != "null" ]
do
{
    echo "name:"
    #cat $filename | jq ".results[$j].name, .results[$j].path, .results[$j].modified_by, .results[$j].modified" | awk 'BEGIN{FS="\n"} {print "name :" $1, "path :"$2,"modified_by :"$3, "modified :"$4}' 
    cat $filename | jq .results[$j].name   
    echo "path:"
    cat $filename | jq .results[$j].path  
    echo "modified_by:"
    cat $filename | jq .results[$j].modified_by 	
    echo "modified:"
    cat $filename | jq .results[$j].modified 
    echo " "

    j=$[$j+1]
    s11=`cat $filename | jq .results[$j].name`
    str1=$s11
    } >> final_report	
done 	   

{
    echo " " 
    echo " " 
} >> final_report

}

Authorization ()
{
     docker login artifactorycn.netcracker.com:17008
     AUTH=$(cat ~/.docker/config.json | grep -A 1 -F "artifactorycn.netcracker.com:17" | grep -oE "auth.*" -m 1 | sed 's/.*: *"//g' | sed 's/".*//g')
     curl  -H "Authorization: Basic $AUTH"
}

MyAuthorization ()
{
    echo "Enter login"
    read log
    echo "Enter password"
    read -s password
}

ListRep ()
{
    curl -u $log:$password  -X GET "https://artifactorycn.netcracker.com/api/repositories" > ListRep
}

ListProperties ()
{
    namerep=$1
    p=`curl -u $log:$password -X GET "https://artifactorycn.netcracker.com/api/storage/$namerep?properties" > prop`   
}

formCurlAQL()
{
    local namerep=$1 
    local nproperty=$2
    p=`curl  -u $log:$password  -H Content-Type:text/plain -X POST -d "items.find({\"repo\": \"$namerep\"},{\"name\" : { "'"$match"'":\"*.*\"}},{\"modified\":{"'"$before"'":\""$nproperty"d\"}}).include(\"name\",\"repo\",\"path\",\"modified_by\",\"modified\")"  "https://artifactorycn.netcracker.com/api/search/aql"  > CurlAQL `
}
parseCurlAQL () 
{   
    local paramscript=$1
    property=`cat prop | jq '.properties."artifacts.lifetime.days"[0]'`

    if [ "$property" !=  "null" ]  && [ "$property" != "\"\"" ] 
    then
    echo "artifacts.lifetime.days = $property"
    nproperty=`echo $property | tr -d "\""`
    nproperty=$[$nproperty-$paramscript]
    echo "nproperty = $nproperty"
    echo "request a list of files to be deleted after $paramscript days"
    if (echo "$nproperty" | grep -E -q "^?[0-9]+$"); then

	formCurlAQL $str $nproperty

    else 
	echo "Error: The lifetime of files is less then the number of days left"
	i=$[$iter+1]
	cat ListRep |  jq .["$iter"].key > key_rep
	str=`tr -d "\"" < key_rep`		
	continue 
    fi
    echo "parse result"
    parse CurlAQL
    echo "complited"    
    fi
}
repository_handler ()
{
    local paramScript=$1
    iter=0
    cat ListRep |  jq .["$iter"].key > key_rep
    str=`tr -d "\"" < key_rep`
    
    while  [ "$str" != "null" ]
    do

        echo "iter = $iter"
        echo "property query for the repository:"
        echo $str
    
        ListProperties $str
        parseCurlAQL $paramScript
       
        iter=$[$iter+1]
        
        cat ListRep |  jq .["$iter"].key > key_rep
        str=`tr -d "\"" < key_rep`
        echo ""
    done
    
}

removeFiles (){
read -n 1 -p "delete temporary files? (y/[a]):" AMSURE

[ "$AMSURE" = "y" ] || exit
echo "" 
rm -r key_rep
rm -r ListRep
rm -r CurlAQL
rm -r prop
}   