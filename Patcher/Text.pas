unit Text;

interface

uses
  Lib;
  
const
  CR = #13;
  LF = #10;

  CRLF = CR + LF;


const
  Disclaimer =
    'This program will patch MechWarrior 2 for usage under Windows 2000/XP.' + CRLF +
    'Copyright (C) 2006 Chris Porter -- http://www.warp13.co.uk/' +  CRLF +
    '' + CRLF +
    '%VERSION%.' + CRLF +
    '' + CRLF +
    'To continue you must accept the following disclaimer:' + CRLF +
    'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.' + ' IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR' + ' PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT' + ' OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.' + CRLF +
    '' + CRLF +
    'Do you accept and wish to continue?';

implementation

end.
