#!/usr/bin/env bash
############################################
#1. 上传apk到百度云
#2. 获取apk下载链接生成二维码
#3. 上传二维码到百度云
#4. 生成html
#5. 将html上传到百度云
############################################
#-----------------------------------------------------------
TIME=$(date "+%Y-%m-%d%t:%t%T")
YMD=`date "+%Y-%m-%d"`
HHMMSS=`date "+%H%M%S"`
#百度云命令可执行文件路径
BCECMD="/Users/erlei/Library/Baidu/mac-bcecmd-0.3.0/bcecmd"
#远程的bucket名字
BUCKET_NAME="android-pakeage"
#版本号
VERSION="4.0.0"
#远程路径
DEST_DIR="$BUCKET_NAME/jenkins/$VERSION/$YMD/$HHMMSS"
#临时文件路径
TEMP_DIR="/var/tmp/jenkins/build_output/"
#项目路径
PROJECT="/Users/erlei/StudioProjects/app-hitup"
#项目输出文件路径
PROJECT_OUTPUT="$PROJECT/app/build/outputs"
#网页模版文件
TEMPLATE_FILE="/Users/erlei/Desktop/android_apk.html"
#网页输出文件
OUTPUT_HTML_FILE="/Users/erlei/Desktop/android_1_apk.html"
OUTPUT_QRENCODE_FILE="/Users/erlei/Desktop/qrencode.png"
#-----------------------------------------------------------
#清空临时文件夹
rm -rf $TEMP_DIR && mkdir -p $TEMP_DIR
#复制要上传的文件到临时文件夹
find $PROJECT_OUTPUT -name "*.apk" -or -name "*.json" -or -name "*.txt"| xargs -I {} cp {} $TEMP_DIR
#重命名一些文件
for file in $(find $TEMP_DIR -name "*.json" -o -name "*.txt") 
    do mv $file "$TEMP_DIR$VERSION-$(basename $file)"
done
#上传文件夹
# $BCECMD bos cp $TEMP_DIR bos:/$DEST_DIR --recursive

DEST_DIR="bos:/android-pakeage/jenkins/4.0.0/2019-11-21/182045/"
#生成文件列表的html
FILE_LIST_HTML=""
for file in $($BCECMD bos ls "$DEST_DIR/" | awk '{print $5}') 
    do 
        url=$($BCECMD bos gen_signed_url "$DEST_DIR/"$file -e-1)
        FILE_LIST_HTML="$FILE_LIST_HTML<br><a href="$url">$file</a>"
done
#定义方法，替换模版文件中的变量
relpace(){
    sed -i "" "s~\${$1}~$2~g" $OUTPUT_HTML_FILE
}

#生成二维码
$BCECMD bos ls "$DEST_DIR/" | grep .apk | awk '{print $5}'| xargs -I {} echo $DEST_DIR{} | 
xargs -I {} $BCECMD bos gen_signed_url {} -e-1 | xargs qrencode -s 50 -l H -o $OUTPUT_QRENCODE_FILE

#上传二维码图片获取链接
QRCODE_URL=`$BCECMD bos cp $OUTPUT_QRENCODE_FILE $DEST_DIR | awk '{print $4}' | xargs -I {} $BCECMD bos gen_signed_url {} -e-1`

cp $TEMPLATE_FILE $OUTPUT_HTML_FILE
relpace CHANNEL_NAME "baidu"
relpace BRANCH $BRANCH
relpace BUILD_TYPE $BUILD_TYPE
relpace VERSION_CODE $VERSION_CODE
relpace VERSION_NAME $VERSION_NAME
relpace CHANGE_LOG $CHANGE_LOG
relpace SERVER_HOST $SERVER_HO
relpace BUILD_TIMESTAMP "$TIME"
relpace FILE_LIST "$FILE_LIST_HTML"
relpace QRCODE_URL "$QRCODE_URL"

#上传html文件
echo $OUTPUT_HTML_FILE
$BCECMD bos cp $OUTPUT_HTML_FILE $DEST_DIR | awk '{print $4}' | xargs -I {} $BCECMD bos gen_signed_url {} -e-1
