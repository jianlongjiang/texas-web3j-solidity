pragma solidity ^0.4.18;
contract owned {
    address public owner;
    function owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract TexasContract is owned{
    //18 decimals 1ETH=10^18 wei
    uint8 constant decimals = 18;
    //��Լӵ����
    address owner;
    //�����߽���
    uint256 ownerFee;
    //�����߽�������ǧ��֮50,��5%
    uint256 ownerFeeRate=50;
    //0.01��ETH��С��ֵ
    uint256 minBet=(10**uint256(decimals))/100;
    //0.1��ETH����ֵ
    uint256 maxBet=(10**uint256(decimals))/10;
    
    // ���������ϴ���һ�������¼����������ͻ�֪ͨ���пͻ���
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferError(address indexed from, address indexed to, uint256 value);
    event Bonus(address indexed from, uint256 value);
    event Whithdraw(address indexed from, uint256 value);
    struct player{
        //����
        uint256 bonus;
        //��ֵ����
        uint256 times;
        //win
        uint256 bonusWin;
    }
    //���������˻��������
    mapping (address => player) players;
    address[]  playersArray;
    /**
     * ��ʼ����Լ
     */
    function TexasContract(
    ) public {
        //��ʼ����Լ������
        owner=msg.sender;             
    }
    /// ʹ����̫��������
    function () payable public {
        uint amount = msg.value;
        require(amount>=minBet);
        //require(amount<=maxBet);
        addToArray(msg.sender);
        players[msg.sender].times+=1;
        players[msg.sender].bonus+=amount;
        //֪ͨ
        Bonus(msg.sender,amount);
       
    }
    //���õ�ַ��������
    function addToArray(address _player) internal{
        //��������ڣ����õ�ַ�������飬�����Ժ��������
        if(players[msg.sender].times==0){
            playersArray.push(_player);   
        }
    }
    //����Ա������Ϸ������������һ���û�ת�Ƶ���һ��
    function bonusTransfer(address _playerWin,address _playerLose,uint amount) onlyOwner public{
        require(amount>0);
        //�����ҽ���㹻
        require(players[_playerLose].bonus>=amount);
        //������
        uint ownerFeePlus=amount/1000*ownerFeeRate;
        ownerFee=ownerFee+ownerFeePlus;
        uint loseOld=players[_playerLose].bonus;
        uint winOld=players[_playerWin].bonus;
        players[_playerLose].bonus-=amount;
        players[_playerWin].bonus+=amount-ownerFeePlus;
        if(players[_playerLose].bonus+players[_playerWin].bonus==loseOld+winOld-ownerFeePlus){
            //�ɹ�֪ͨ
            Transfer(_playerLose,_playerWin,amount);
        }else{
            //ʧ�����ݻ���
            players[_playerLose].bonus=loseOld;
            players[_playerWin].bonus=winOld;
            //ʧ��֪ͨ
            TransferError(_playerLose,_playerWin,amount);
        }
    }
    //�û��������һ���û�ת�Ƶ���һ��
    function bonusTransfer(address _playerWin,uint amount) public{
        address _playerLose=msg.sender;
        require(amount>0);
        //�����ҽ���㹻
        require(players[_playerLose].bonus>=amount);
        //������
        uint ownerFeePlus=amount/1000*ownerFeeRate;
        ownerFee=ownerFee+ownerFeePlus;
        uint loseOld=players[_playerLose].bonus;
        uint winOld=players[_playerWin].bonus;
        players[_playerLose].bonus-=amount;
        players[_playerWin].bonus+=amount-ownerFeePlus;
        if(players[_playerLose].bonus+players[_playerWin].bonus==loseOld+winOld-ownerFeePlus){
            //�ɹ�֪ͨ
            Transfer(_playerLose,_playerWin,amount);
        }else{
            //ʧ�����ݻ���
            players[_playerLose].bonus=loseOld;
            players[_playerWin].bonus=winOld;
            //ʧ��֪ͨ
            TransferError(_playerLose,_playerWin,amount);
        }
    }
    /**
     * �û���ȡETH
     */
    function whithdraw(uint amount)public{
        require(amount<=players[msg.sender].bonus);
        if(amount<=0){
            amount=players[msg.sender].bonus;
        }
        uint _bonus=players[msg.sender].bonus;
        players[msg.sender].bonus=players[msg.sender].bonus-amount;
        if(_bonus==players[msg.sender].bonus+amount){
            msg.sender.transfer(_bonus);
            //����֪ͨ
            Whithdraw(msg.sender,amount);
        }
    }
    /**
     * �û���ȡ�����ֽ��
     */
    function canWhithdraw() public view returns(uint256 _bonus){
       _bonus= players[msg.sender].bonus;
    }
    /**
     * ����Ա��ȡETH������
     */
    function whithdrawAdmin() onlyOwner public{
        require(this.balance>=ownerFee);
        uint _ownerFee=ownerFee;
        ownerFee=0;
        owner.transfer(_ownerFee);
    }
    /**
     * ����Ա����������ǧ����
     */
    function setRate(uint rate) onlyOwner public {
        ownerFeeRate=rate;
    }
}