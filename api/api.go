package api

import (
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/greycodee/wechat-backup/db"
)

const (
	ListApi     = "/api/chat/list"
	DetailApi   = "/api/chat/detail"
	UserInfoApi = "/api/user/info"
	MyInfoApi   = "/api/user/myinfo"
	ImgApi      = "/api/media/img"
	VideoApi    = "/api/media/video"
	VoiceApi    = "/api/media/voice"
	DetailKWApi = "/api/chat/detailkw"
	MsgDateApi  = "/api/chat/msgdate"
	MedListApi  = "/apt/media/list"
)

type Api struct {
	wcdb   *db.WCDB
	Engine *gin.Engine
}

func New(dbPath string) *Api {
	a := &Api{}
	a.wcdb = db.InitWCDB(dbPath)
	a.Engine = gin.New()
	a.Engine.Use(gin.Recovery())

	return a
}

func (a Api) listHandler(c *gin.Context) {
	pageIndex, _ := strconv.Atoi(c.DefaultQuery("pageIndex", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))
	name := c.Query("name")
	all, _ := strconv.ParseBool(c.DefaultQuery("all", "false"))

	result := a.wcdb.ChatList(pageIndex-1, pageSize, all, name)
	// 聊天列表
	c.JSON(200, result)
}

func (a Api) detailHandler(c *gin.Context) {
	pageIndex, _ := strconv.Atoi(c.DefaultQuery("pageIndex", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))
	talker := c.Query("talker")
	c.JSON(200, a.wcdb.ChatDetailList(talker, pageIndex-1, pageSize))
}

func (a Api) userInfoHandler(c *gin.Context) {
	userName := c.Query("username")
	c.JSON(200, a.wcdb.GetUserInfo(userName))
}

func (a Api) myInfoHandler(c *gin.Context) {
	c.JSON(200, a.wcdb.GetMyInfo())
}

func (a Api) imgHandler(c *gin.Context) {
	msgId := c.Query("msgId")
	c.JSON(200, a.wcdb.GetImgPath(msgId))
}

func (a Api) videoHandler(c *gin.Context) {
	msgId := c.Query("msgId")
	fmt.Println("msgId: ", msgId)
	c.JSON(200, a.wcdb.GetVideoPath(msgId))
}

func (a Api) voiceHandler(c *gin.Context) {
	msgId := c.Query("msgId")
	c.JSON(200, a.wcdb.GetVoicePath(msgId))
}

func (a Api) detailKeyWordHandler(c *gin.Context) {
	createTime, _ := strconv.ParseInt(c.DefaultQuery("createTime", "1"), 10, 64)
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))
	talker := c.Query("talker")
	keyWord := c.DefaultQuery("keyWord", "")
	keyWord = strings.ReplaceAll(keyWord, "'", "''")
	// keyWord = strings.ReplaceAll(keyWord, ".", "..")
	log.Printf("keyWord %s", keyWord)
	c.JSON(200, a.wcdb.ChatDetailListKeyWord(talker, keyWord, createTime, pageSize))
}

func (a Api) MessageDateHandler(c *gin.Context) {
	talker := c.Query("talker")
	c.JSON(200, a.wcdb.ChatMessageDate(talker))
}

func (a Api) MediaListHandler(c *gin.Context) {
	log.Println("MediaListHandler start")
	defer log.Println("MediaListHandler end")
	talker := c.Query("talker")
	pageIndex, _ := strconv.Atoi(c.DefaultQuery("pageIndex", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "28"))
	c.JSON(200, a.wcdb.ChatDetailMediaList(talker, pageIndex-1, pageSize))
}

func (a Api) Router() http.Handler {
	a.Engine.GET(ListApi, a.listHandler)
	a.Engine.GET(DetailApi, a.detailHandler)
	a.Engine.GET(UserInfoApi, a.userInfoHandler)
	a.Engine.GET(MyInfoApi, a.myInfoHandler)
	a.Engine.GET(ImgApi, a.imgHandler)
	a.Engine.GET(VideoApi, a.videoHandler)
	a.Engine.GET(VoiceApi, a.voiceHandler)
	a.Engine.GET(DetailKWApi, a.detailKeyWordHandler)
	a.Engine.GET(MsgDateApi, a.MessageDateHandler)
	a.Engine.GET(MedListApi, a.MediaListHandler)
	return a.Engine
}
