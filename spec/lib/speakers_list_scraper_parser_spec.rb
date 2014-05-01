# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/speakers_list_parser'

describe SpeakersListParser do

  before(:all) do
    @parser = SpeakersListParser.new()
  end
  
  describe "when making a new Speakers List parser" do 
  
    it "should be a Speakers List parser" do
      @parser.should be_an_instance_of(SpeakersListParser)
    end
    
    it "should look at the Speakers List URL" do
      @parser.page.should eq "http://www.lordswhips.org.uk/speakers-lists"
    end
    
    it "should start with an empty list of Speakers Lists" do
      @parser.speakers_lists.should eq []
    end
    
  end
  
  describe "after successfully scraping a Speakers List page" do

    before(:each) do
        html = %Q|<div class="speaker_panel">
        <div class="clr40"></div>
        <span class="toleft">(Click the </span>
        <img src="/Content/images/icon-plus-square.jpg" class="toleft ml5 mr5 mu7"><span class="toleft">icon underneath a debate title to add your name to that list.)</span>
        <div class="clr10"></div>
        
                <div class="datepanel first" id="debate-533bc39798f9411824e95b7a">
                    <a name="debate-533bc39798f9411824e95b7a"></a>
                    <span class="date">Tuesday 6 May 2014</span>
                    <div class="topicpanelwrap">
                        <img src="/Content/images/speaker-panel-arrow.png" class="topicarrow">
                        <div class="topicpanel"> 
                            <p>Lord Cope of Berkeley&nbsp;to move that this House takes note of the actions which have been taken following the publication in 2013 of the Report of the Select Committee on Small and Medium Sized Enterprises (HL Paper 131).</p>

                            
                        </div><!--end of topicpanel-->
                    </div><!--end of topicpanelwrap-->
                    <div class="clr5"></div>
                    <div class="clr15"></div>
                    <div class="speaklist">
                            <span class="toleft">Speakers (12) in alphabetical order:</span>
                            <a href="/print-debate/533bc39798f9411824e95b7a" class="smbtnprint toright" target="_blank">Print this list</a>
                            <div class="clr10"></div>
                                <ul>
                                        <li>
                                                                                        B&nbsp;Cohen of Pimlico
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Cope of Berkeley
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Cotter
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Giddens
                                            
                                        </li>
                                        <li>
                                                                                            <span class="index">5</span>
                                            L&nbsp;Grade of Yarmouth
                                            
                                        </li>
                                </ul>
                                <ul>
                                        <li>
                                                                                        L&nbsp;Green of Hurstpierpoint
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Haskel
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Haskins
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Leigh of Hurley
                                            
                                        </li>
                                        <li>
                                                                                            <span class="index">10</span>
                                            L&nbsp;Livingston of Parkhead (Minister)
                                            
                                        </li>
                                </ul>
                                <ul>
                                        <li>
                                                                                        L&nbsp;Stevenson of Balmacara
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Storey
                                            
                                        </li>
                                </ul>
                    </div>  <!--end of speaklist-->
                    
                </div><!--end of datepanel-->
                <div class="datepanel " id="debate-534503cb98f9411854eef458">
                    <a name="debate-534503cb98f9411854eef458"></a>
                    <span class="date">Wednesday 7 May 2014</span>
                    <div class="topicpanelwrap">
                        <img src="/Content/images/speaker-panel-arrow.png" class="topicarrow">
                        <div class="topicpanel"> 
                            <p>Lord Wei&nbsp;to ask Her Majesty’s Government what assessment they have made of the recommendations of the report of the All-Party Parliamentary Group on East Asian Business on foreign investment from China into the United Kingdom <em>(Question for Short Debate to be taken in Grand Committee, 1 hour)</em>.&nbsp;</p>

                            
                        </div><!--end of topicpanel-->
                    </div><!--end of topicpanelwrap-->
                    <div class="clr5"></div>
                    <div class="clr15"></div>
                    <div class="speaklist">
                            <span class="toleft">Speakers (4) in alphabetical order:</span>
                            <a href="/print-debate/534503cb98f9411854eef458" class="smbtnprint toright" target="_blank">Print this list</a>
                            <div class="clr10"></div>
                                <ul>
                                        <li>
                                                                                        L&nbsp;Davidson of Glen Clova
                                            
                                        </li>
                                        <li>
                                                                                        B&nbsp;Falkner of Margravine
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Livingston of Parkhead (Minister)
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Wei
                                            
                                        </li>
                                </ul>
                    </div>  <!--end of speaklist-->
                    
                </div><!--end of datepanel-->
                <div class="datepanel " id="debate-5345040598f9411854eef459">
                    <a name="debate-5345040598f9411854eef459"></a>
                    <span class="date">Wednesday 7 May 2014</span>
                    <div class="topicpanelwrap">
                        <img src="/Content/images/speaker-panel-arrow.png" class="topicarrow">
                        <div class="topicpanel"> 
                            <p>Lord Pearson of Rannoch&nbsp;to ask Her Majesty’s Government whether, in the course of their renewal of the BBC’s Charter and Guidelines in 2016, they will take into account the BBC’s coverage of European Union matters, in the light of its recognition of the need for greater breadth in such coverage following publication of the report of the Independent Panel led by Lord Wilson of Dinton in 2005 <em>(Question for Short Debate to be taken in Grand Committee, 1 hour)</em>.&nbsp;</p>

                            
                        </div><!--end of topicpanel-->
                    </div><!--end of topicpanelwrap-->
                    <div class="clr5"></div>
                    <div class="clr15"></div>
                    <div class="speaklist">
                            <span class="toleft">Speakers (6) in alphabetical order:</span>
                            <a href="/print-debate/5345040598f9411854eef459" class="smbtnprint toright" target="_blank">Print this list</a>
                            <div class="clr10"></div>
                                <ul>
                                        <li>
                                                                                        L&nbsp;Bates (Minister)
                                            
                                        </li>
                                        <li>
                                                                                        B&nbsp;Bonham-Carter of Yarnbury
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Giddens
                                            
                                        </li>
                                        <li>
                                                                                        B&nbsp;Jones of Whitchurch
                                            
                                        </li>
                                        <li>
                                                                                            <span class="index">5</span>
                                            L&nbsp;Pearson of Rannoch
                                            
                                        </li>
                                </ul>
                                <ul>
                                        <li>
                                                                                        L&nbsp;Teverson
                                            
                                        </li>
                                </ul>
                    </div>  <!--end of speaklist-->
                    
                </div><!--end of datepanel-->
                <div class="datepanel " id="debate-5345047b98f9411854eef45a">
                    <a name="debate-5345047b98f9411854eef45a"></a>
                    <span class="date">Thursday 8 May 2014</span>
                    <div class="topicpanelwrap">
                        <img src="/Content/images/speaker-panel-arrow.png" class="topicarrow">
                        <div class="topicpanel"> 
                            <p>Lord Faulks&nbsp;to move that this House takes note of the United Kingdom’s 2014 justice and home affairs opt-out decision.</p>

                            
                        </div><!--end of topicpanel-->
                    </div><!--end of topicpanelwrap-->
                    <div class="clr5"></div>
                    <div class="clr15"></div>
                    <div class="speaklist">
                            <span class="toleft">Speakers (10) in alphabetical order:</span>
                            <a href="/print-debate/5345047b98f9411854eef45a" class="smbtnprint toright" target="_blank">Print this list</a>
                            <div class="clr10"></div>
                                <ul>
                                        <li>
                                                                                        L&nbsp;Boswell of Aynho
                                            
                                        </li>
                                        <li>
                                                                                        B&nbsp;Corston
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Faulks (Minister)
                                            
                                                &nbsp;(Government opener)
                                        </li>
                                        <li>
                                                                                        B&nbsp;Hamwee
                                            
                                        </li>
                                        <li>
                                                                                            <span class="index">5</span>
                                            L&nbsp;Hannay of Chiswick
                                            
                                        </li>
                                </ul>
                                <ul>
                                        <li>
                                                                                        L&nbsp;Kennedy of Southwark
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Pearson of Rannoch
                                            
                                        </li>
                                        <li>
                                                                                        B&nbsp;Smith of Basildon
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Taylor of Holbeach (Minister)
                                            
                                                &nbsp;(Government winder)
                                        </li>
                                        <li>
                                                                                            <span class="index">10</span>
                                            L&nbsp;Teverson
                                            
                                        </li>
                                </ul>
                    </div>  <!--end of speaklist-->
                    
                </div><!--end of datepanel-->
                <div class="datepanel " id="debate-534504a898f9411854eef45b">
                    <a name="debate-534504a898f9411854eef45b"></a>
                    <span class="date">Thursday 8 May 2014</span>
                    <div class="topicpanelwrap">
                        <img src="/Content/images/speaker-panel-arrow.png" class="topicarrow">
                        <div class="topicpanel"> 
                            <p>Proposed National Policy Statement for National Networks -&nbsp;consideration in Grand Committee&nbsp;</p>

                            
                        </div><!--end of topicpanel-->
                    </div><!--end of topicpanelwrap-->
                    <div class="clr5"></div>
                    <div class="clr15"></div>
                    <div class="speaklist">
                            <span class="toleft">Speakers (3) in alphabetical order:</span>
                            <a href="/print-debate/534504a898f9411854eef45b" class="smbtnprint toright" target="_blank">Print this list</a>
                            <div class="clr10"></div>
                                <ul>
                                        <li>
                                                                                        L&nbsp;Bradshaw
                                            
                                        </li>
                                        <li>
                                                                                        B&nbsp;Kramer (Minister)
                                            
                                        </li>
                                        <li>
                                                                                        L&nbsp;Rosser
                                            
                                        </li>
                                </ul>
                    </div>  <!--end of speaklist-->
                    
                </div><!--end of datepanel-->
            <div class="lgreydivider"><hr></div>
            <div class="clr10"></div>

<table cellpadding="0" cellspacing="0" border="0">
    <tbody><tr>
        <td align="left" class="txt000"><strong>Week beginning Monday 5 May 2014</strong></td>
        <td align="left">
            <div class="navwrap">
                    <a href="/speakers-lists/28042014" class="prevlnk">Previous Week</a>

                <a href="/speakers-lists/12052014" class="nextlnk">Next Week</a>
            </div>
            <!--end of wrap the speaker nav-->
        </td>
    </tr>
</tbody></table>    </div>|
        
        @response = mock("Fake Response")
        @response.stubs(:body).returns(html)
        RestClient.expects(:get).returns(@response)
     end
  
  end
  
end