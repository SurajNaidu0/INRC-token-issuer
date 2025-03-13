import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
// Proper image import
import logoImage from './assets/pngwing.com (1).png';

declare global {
    interface Window {
        ethereum?: any;
    }
}

// Contract ABI
const contractABI = [
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)",
    "function totalSupply() view returns (uint256)",
    "function balanceOf(address) view returns (uint256)",
    "function allowance(address, address) view returns (uint256)",
    "function transfer(address to, uint256 value) returns (bool)",
    "function approve(address spender, uint256 value) returns (bool)",
    "function transferFrom(address from, address to, uint256 value) returns (bool)",
    "function mint(address to, uint256 amount)",
    "function burn(address from, uint256 amount)",
    "function blacklist(address)",
    "function unBlacklist(address)",
    "function pause()",
    "function unpause()",
    "function transferOwnership(address newOwner)",
    "function owner() view returns (address)",
    "function isBlacklisted(address) view returns (bool)",
    "function paused() view returns (bool)"
];

// Contract address (update if deployed elsewhere)
const contractAddress = "0x1c2ff585120219e552a4c3a6ce5b6345cb1efa2c";

const App: React.FC = () => {
    const [currentView, setCurrentView] = useState<'home' | 'user' | 'admin'>('home');
    const [walletConnected, setWalletConnected] = useState(false);
    const [userAddress, setUserAddress] = useState('');
    const [isOwner, setIsOwner] = useState(false);
    const [userBalance, setUserBalance] = useState('0');
    const [contract, setContract] = useState<ethers.Contract | null>(null);
    const [tokenData, setTokenData] = useState({
        name: '',
        symbol: '',
        decimals: 0,
        totalSupply: '0',
        contractAddress: contractAddress,
    });

    const connectWallet = async () => {
        if (typeof window.ethereum !== 'undefined') {
            try {
                const provider = new ethers.BrowserProvider(window.ethereum);
                const signer = await provider.getSigner();
                const address = await signer.getAddress();
                const contract = new ethers.Contract(contractAddress, contractABI, signer);

                setContract(contract);
                setUserAddress(address);
                setWalletConnected(true);

                const name = await contract.name();
                const symbol = await contract.symbol();
                const decimals = await contract.decimals();
                const totalSupply = ethers.formatUnits(await contract.totalSupply(), decimals);
                const balance = ethers.formatUnits(await contract.balanceOf(address), decimals);
                const owner = await contract.owner();

                setTokenData({ name, symbol, decimals, totalSupply, contractAddress });
                setUserBalance(balance);
                setIsOwner(address.toLowerCase() === owner.toLowerCase());
            } catch (error) {
                console.error("Error connecting wallet:", error);
                alert("Failed to connect wallet. Please try again.");
            }
        } else {
            alert("Please install MetaMask!");
        }
    };

    // Rest of your component code...
    const disconnectWallet = () => {
        setWalletConnected(false);
        setUserAddress('');
        setContract(null);
        setCurrentView('home');
        setIsOwner(false);
    };

    const goToUserDashboard = () => walletConnected && setCurrentView('user');
    const goToAdminDashboard = () => walletConnected && setCurrentView('admin');

    return (
        <div className="flex flex-col min-h-screen" style={{ fontFamily: 'Times New Roman, Times, serif' }}>
            <Header
                walletConnected={walletConnected}
                userAddress={userAddress}
                connectWallet={connectWallet}
                disconnectWallet={disconnectWallet}
                goToUserDashboard={goToUserDashboard}
                goToAdminDashboard={goToAdminDashboard}
                currentView={currentView}
                setCurrentView={setCurrentView}
            />
            <DonateSidebar position="left" />
            <DonateSidebar position="right" />

            {currentView === 'home' && <MainContent logoImage={logoImage} />}
            {currentView === 'user' && (
                <UserDashboard
                    tokenData={tokenData}
                    userAddress={userAddress}
                    userBalance={userBalance}
                    contract={contract}
                />
            )}
            {currentView === 'admin' && (
                <AdminDashboard
                    tokenData={tokenData}
                    userAddress={userAddress}
                    isOwner={isOwner}
                    setCurrentView={setCurrentView}
                    contract={contract}
                />
            )}
        </div>
    );
};

// Header Component
interface HeaderProps {
    walletConnected: boolean;
    userAddress: string;
    connectWallet: () => void;
    disconnectWallet: () => void;
    goToUserDashboard: () => void;
    goToAdminDashboard: () => void;
    currentView: string;
    setCurrentView: (view: 'home' | 'user' | 'admin') => void;
}

const Header: React.FC<HeaderProps> = ({
                                                 walletConnected,
                                                 userAddress,
                                                 connectWallet,
                                                 disconnectWallet,
                                                 goToUserDashboard,
                                                 goToAdminDashboard,
                                           setCurrentView,
                                             }) => (
    <div className="flex justify-between items-center px-10 py-5">
        <div className="flex gap-5">
            <a href="#" onClick={() => setCurrentView('home')} className="text-black no-underline text-lg hover:underline">FAQs</a>
            <a href="#" onClick={() => setCurrentView('home')} className="text-black no-underline text-lg hover:underline">Why $INRC</a>
            {walletConnected && (
                <a href="#" onClick={goToAdminDashboard} className="text-black no-underline text-lg hover:underline">Admin Login</a>
            )}
        </div>
        <div>
            <a href="#" onClick={() => setCurrentView('home')} className="text-black no-underline text-lg">$INRC</a>
        </div>
        <div>
            {!walletConnected ? (
                <button onClick={connectWallet} className="text-black no-underline text-lg hover:underline">
                    Connect Wallet
                </button>
            ) : (
                <div className="flex gap-5">
                    <a href="#" onClick={goToUserDashboard} className="text-black no-underline text-lg hover:underline">
                        {userAddress ? `${userAddress.slice(0, 6)}...${userAddress.slice(-4)}` : 'User Dashboard'}
                    </a>
                    <button onClick={disconnectWallet} className="text-black no-underline text-lg hover:underline">
                        Disconnect
                    </button>
                </div>
            )}
        </div>
    </div>
);

// DonateSidebar Component
interface DonateSidebarProps {
    position: 'left' | 'right';
}

const DonateSidebar: React.FC<DonateSidebarProps> = ({ position }) => {
    const isLeft = position === 'left';
    const baseClasses = "fixed top-0 bottom-0 flex justify-center items-center p-5 uppercase font-bold tracking-wider text-gray-800";
    const positionClasses = position === 'left' ? 'left-0' : 'right-0';
    const customStyles = {
        writingMode: 'vertical-lr' as const,
        animation: isLeft ? 'moveUpDownLeft 5s infinite alternate' : 'moveUpDownRight 5s infinite alternate',
        ...(isLeft && { transform: 'rotate(180deg)' }),
    };

    return (
        <>
            <style>
                {`
                    @keyframes moveUpDownLeft {
                        0% { transform: translateY(0) rotate(180deg); }
                        100% { transform: translateY(50px) rotate(180deg); }
                    }
                    @keyframes moveUpDownRight {
                        0% { transform: translateY(0); }
                        100% { transform: translateY(50px); }
                    }
                `}
            </style>
            <div className={`${baseClasses} ${positionClasses}`} style={customStyles}>
                DONATE NOW
            </div>
        </>
    );
};

// MainContent Component with updated image prop
interface MainContentProps {
    logoImage: string;
}

const MainContent: React.FC<MainContentProps> = ({ logoImage }) => (
    <div className="flex flex-col items-center justify-center flex-grow py-20 px-24 text-center">
        <img src={logoImage} alt="$INRC Token" className="mb-10" width={300} height={300} />
        <h1 className="text-6xl font-normal leading-tight max-w-6xl" style={{ fontFamily: 'Times New Roman, Times, serif' }}>
            Lets Make India Great Again
        </h1>
    </div>
);

// UserDashboard Component (remains the same)
interface UserDashboardProps {
    tokenData: { name: string; symbol: string; decimals: number; totalSupply: string; contractAddress: string };
    userAddress: string;
    userBalance: string;
    contract: ethers.Contract | null;
}

const UserDashboard: React.FC<UserDashboardProps> = ({
                                                         tokenData,
// changed from userAddress
                                                         userBalance,
                                                         contract
                                                     }) => {
    const [recipient, setRecipient] = useState('');
    const [amount, setAmount] = useState('');
    const [spender, setSpender] = useState('');
    const [allowanceAmount, setAllowanceAmount] = useState('');
    const [transferFromFrom, setTransferFromFrom] = useState('');
    const [transferFromTo, setTransferFromTo] = useState('');
    const [transferFromAmount, setTransferFromAmount] = useState('');
    const [transferStatus, setTransferStatus] = useState<'processing' | 'success' | 'error' | null>(null);
    const [approveStatus, setApproveStatus] = useState<'processing' | 'success' | 'error' | null>(null);
    const [transferFromStatus, setTransferFromStatus] = useState<'processing' | 'success' | 'error' | null>(null);

    const handleTransfer = async () => {
        if (!contract || !recipient || !amount) return;
        try {
            setTransferStatus('processing');
            const tx = await contract.transfer(recipient, ethers.parseUnits(amount, tokenData.decimals));
            await tx.wait();
            setTransferStatus('success');
            setTimeout(() => setTransferStatus(null), 3000);
        } catch (error) {
            console.error("Transfer error:", error);
            setTransferStatus('error');
            setTimeout(() => setTransferStatus(null), 3000);
        }
    };

    const handleApprove = async () => {
        if (!contract || !spender || !allowanceAmount) return;
        try {
            setApproveStatus('processing');
            const tx = await contract.approve(spender, ethers.parseUnits(allowanceAmount, tokenData.decimals));
            await tx.wait();
            setApproveStatus('success');
            setTimeout(() => setApproveStatus(null), 3000);
        } catch (error) {
            console.error("Approve error:", error);
            setApproveStatus('error');
            setTimeout(() => setApproveStatus(null), 3000);
        }
    };

    const handleTransferFrom = async () => {
        if (!contract || !transferFromFrom || !transferFromTo || !transferFromAmount) return;
        try {
            setTransferFromStatus('processing');
            const tx = await contract.transferFrom(
                transferFromFrom,
                transferFromTo,
                ethers.parseUnits(transferFromAmount, tokenData.decimals)
            );
            await tx.wait();
            setTransferFromStatus('success');
            setTimeout(() => setTransferFromStatus(null), 3000);
        } catch (error) {
            console.error("TransferFrom error:", error);
            setTransferFromStatus('error');
            setTimeout(() => setTransferFromStatus(null), 3000);
        }
    };

    return (
        <div className="flex flex-col items-center justify-center flex-grow py-10 px-24">
            <h1 className="text-3xl font-normal mb-8">User Dashboard</h1>
            <div className="w-full max-w-2xl bg-gray-50 p-8 rounded">
                <div className="mb-6">
                    <h2 className="text-xl mb-4">Token Information</h2>
                    <div className="grid grid-cols-2 gap-2">
                        <div>Name:</div><div>{tokenData.name}</div>
                        <div>Symbol:</div><div>{tokenData.symbol}</div>
                        <div>Decimals:</div><div>{tokenData.decimals}</div>
                        <div>Total Supply:</div><div>{tokenData.totalSupply} {tokenData.symbol}</div>
                        <div>Your Balance:</div><div>{userBalance} {tokenData.symbol}</div>
                        <div>Contract Address:</div><div className="break-all">{tokenData.contractAddress}</div>
                    </div>
                </div>
                <div className="mb-6">
                    <h2 className="text-xl mb-4">Transfer Tokens</h2>
                    <div className="flex flex-col gap-3">
                        <input type="text" placeholder="Recipient Address" className="p-2 border rounded" value={recipient} onChange={(e) => setRecipient(e.target.value)} />
                        <input type="text" placeholder="Amount" className="p-2 border rounded" value={amount} onChange={(e) => setAmount(e.target.value)} />
                        <button onClick={handleTransfer} disabled={transferStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {transferStatus === 'processing' ? 'Processing...' : 'Transfer'}
                        </button>
                        {transferStatus === 'success' && <div className="text-green-600">Transfer successful!</div>}
                        {transferStatus === 'error' && <div className="text-red-600">Transfer failed!</div>}
                    </div>
                </div>
                <div className="mb-6">
                    <h2 className="text-xl mb-4">Approve Spender</h2>
                    <div className="flex flex-col gap-3">
                        <input type="text" placeholder="Spender Address" className="p-2 border rounded" value={spender} onChange={(e) => setSpender(e.target.value)} />
                        <input type="text" placeholder="Amount to Approve" className="p-2 border rounded" value={allowanceAmount} onChange={(e) => setAllowanceAmount(e.target.value)} />
                        <button onClick={handleApprove} disabled={approveStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {approveStatus === 'processing' ? 'Processing...' : 'Approve'}
                        </button>
                        {approveStatus === 'success' && <div className="text-green-600">Approval successful!</div>}
                        {approveStatus === 'error' && <div className="text-red-600">Approval failed!</div>}
                    </div>
                </div>
                <div>
                    <h2 className="text-xl mb-4">Transfer From</h2>
                    <div className="flex flex-col gap-3">
                        <input type="text" placeholder="From Address" className="p-2 border rounded" value={transferFromFrom} onChange={(e) => setTransferFromFrom(e.target.value)} />
                        <input type="text" placeholder="To Address" className="p-2 border rounded" value={transferFromTo} onChange={(e) => setTransferFromTo(e.target.value)} />
                        <input type="text" placeholder="Amount" className="p-2 border rounded" value={transferFromAmount} onChange={(e) => setTransferFromAmount(e.target.value)} />
                        <button onClick={handleTransferFrom} disabled={transferFromStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {transferFromStatus === 'processing' ? 'Processing...' : 'Transfer From'}
                        </button>
                        {transferFromStatus === 'success' && <div className="text-green-600">Transfer From successful!</div>}
                        {transferFromStatus === 'error' && <div className="text-red-600">Transfer From failed!</div>}
                    </div>
                </div>
            </div>
        </div>
    );
};

// AdminDashboard Component
interface AdminDashboardProps {
    tokenData: { name: string; symbol: string; decimals: number; totalSupply: string; contractAddress: string };
    userAddress: string;
    isOwner: boolean;
    setCurrentView: (view: 'home' | 'user' | 'admin') => void;
    contract: ethers.Contract | null;
}

const AdminDashboard: React.FC<AdminDashboardProps> = ({ tokenData,isOwner, setCurrentView, contract }) => {
    const [isPaused, setIsPaused] = useState(false);
    const [mintTo, setMintTo] = useState('');
    const [mintAmount, setMintAmount] = useState('');
    const [burnFrom, setBurnFrom] = useState('');
    const [burnAmount, setBurnAmount] = useState('');
    const [blacklistAddress, setBlacklistAddress] = useState('');
    const [unblacklistAddress, setUnblacklistAddress] = useState('');
    const [newOwnerAddress, setNewOwnerAddress] = useState('');
    const [pauseStatus, setPauseStatus] = useState<'processing' | 'success' | 'error' | null>(null);
    const [mintStatus, setMintStatus] = useState<'processing' | 'success' | 'error' | null>(null);
    const [burnStatus, setBurnStatus] = useState<'processing' | 'success' | 'error' | null>(null);
    const [blacklistStatus, setBlacklistStatus] = useState<'processing' | 'success' | 'error' | null>(null);
    const [unblacklistStatus, setUnblacklistStatus] = useState<'processing' | 'success' | 'error' | null>(null);
    const [transferOwnershipStatus, setTransferOwnershipStatus] = useState<'processing' | 'success' | 'error' | null>(null);

    useEffect(() => {
        if (contract) {
            contract.paused().then(setIsPaused).catch(console.error);
        }
    }, [contract]);

    const handleTogglePause = async () => {
        if (!contract) return;
        try {
            setPauseStatus('processing');
            const tx = isPaused ? await contract.unpause() : await contract.pause();
            await tx.wait();
            setIsPaused(!isPaused);
            setPauseStatus('success');
            setTimeout(() => setPauseStatus(null), 3000);
        } catch (error) {
            console.error("Toggle pause error:", error);
            setPauseStatus('error');
            setTimeout(() => setPauseStatus(null), 3000);
        }
    };

    const handleMint = async () => {
        if (!contract || !mintTo || !mintAmount) return;
        try {
            setMintStatus('processing');
            const tx = await contract.mint(mintTo, ethers.parseUnits(mintAmount, tokenData.decimals));
            await tx.wait();
            setMintStatus('success');
            setTimeout(() => setMintStatus(null), 3000);
        } catch (error) {
            console.error("Mint error:", error);
            setMintStatus('error');
            setTimeout(() => setMintStatus(null), 3000);
        }
    };

    const handleBurn = async () => {
        if (!contract || !burnFrom || !burnAmount) return;
        try {
            setBurnStatus('processing');
            const tx = await contract.burn(burnFrom, ethers.parseUnits(burnAmount, tokenData.decimals));
            await tx.wait();
            setBurnStatus('success');
            setTimeout(() => setBurnStatus(null), 3000);
        } catch (error) {
            console.error("Burn error:", error);
            setBurnStatus('error');
            setTimeout(() => setBurnStatus(null), 3000);
        }
    };

    const handleBlacklist = async () => {
        if (!contract || !blacklistAddress) return;
        try {
            setBlacklistStatus('processing');
            const tx = await contract.blacklist(blacklistAddress);
            await tx.wait();
            setBlacklistStatus('success');
            setTimeout(() => setBlacklistStatus(null), 3000);
        } catch (error) {
            console.error("Blacklist error:", error);
            setBlacklistStatus('error');
            setTimeout(() => setBlacklistStatus(null), 3000);
        }
    };

    const handleUnblacklist = async () => {
        if (!contract || !unblacklistAddress) return;
        try {
            setUnblacklistStatus('processing');
            const tx = await contract.unBlacklist(unblacklistAddress);
            await tx.wait();
            setUnblacklistStatus('success');
            setTimeout(() => setUnblacklistStatus(null), 3000);
        } catch (error) {
            console.error("Unblacklist error:", error);
            setUnblacklistStatus('error');
            setTimeout(() => setUnblacklistStatus(null), 3000);
        }
    };

    const handleTransferOwnership = async () => {
        if (!contract || !newOwnerAddress) return;
        try {
            setTransferOwnershipStatus('processing');
            const tx = await contract.transferOwnership(newOwnerAddress);
            await tx.wait();
            setTransferOwnershipStatus('success');
            setTimeout(() => setTransferOwnershipStatus(null), 3000);
        } catch (error) {
            console.error("Transfer ownership error:", error);
            setTransferOwnershipStatus('error');
            setTimeout(() => setTransferOwnershipStatus(null), 3000);
        }
    };

    if (!isOwner) {
        return (
            <div className="flex flex-col items-center justify-center flex-grow py-10 px-24">
                <h1 className="text-3xl font-normal mb-4">Admin Access Denied</h1>
                <p>You are not the owner of this contract.</p>
                <button onClick={() => setCurrentView('user')} className="mt-4 p-2 bg-gray-200 rounded hover:bg-gray-300">
                    Return to User Dashboard
                </button>
            </div>
        );
    }

    return (
        <div className="flex flex-col items-center justify-center flex-grow py-10 px-24">
            <h1 className="text-3xl font-normal mb-8">Admin Dashboard</h1>
            <div className="w-full max-w-2xl bg-gray-50 p-8 rounded">
                <div className="mb-6">
                    <h2 className="text-xl mb-4">Contract Status</h2>
                    <div className="flex items-center gap-4">
                        <div>Contract is currently: {isPaused ? 'PAUSED' : 'ACTIVE'}</div>
                        <button onClick={handleTogglePause} disabled={pauseStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {pauseStatus === 'processing' ? 'Processing...' : (isPaused ? 'Unpause Contract' : 'Pause Contract')}
                        </button>
                    </div>
                    {pauseStatus === 'success' && <div className="text-green-600 mt-2">Contract status updated successfully!</div>}
                    {pauseStatus === 'error' && <div className="text-red-600 mt-2">Failed to update contract status!</div>}
                </div>
                <div className="mb-6">
                    <h2 className="text-xl mb-4">Mint Tokens</h2>
                    <div className="flex flex-col gap-3">
                        <input type="text" placeholder="Recipient Address" className="p-2 border rounded" value={mintTo} onChange={(e) => setMintTo(e.target.value)} />
                        <input type="text" placeholder="Amount to Mint" className="p-2 border rounded" value={mintAmount} onChange={(e) => setMintAmount(e.target.value)} />
                        <button onClick={handleMint} disabled={mintStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {mintStatus === 'processing' ? 'Processing...' : 'Mint Tokens'}
                        </button>
                        {mintStatus === 'success' && <div className="text-green-600">Minting successful!</div>}
                        {mintStatus === 'error' && <div className="text-red-600">Minting failed!</div>}
                    </div>
                </div>
                <div className="mb-6">
                    <h2 className="text-xl mb-4">Burn Tokens</h2>
                    <div className="flex flex-col gap-3">
                        <input type="text" placeholder="Address to Burn From" className="p-2 border rounded" value={burnFrom} onChange={(e) => setBurnFrom(e.target.value)} />
                        <input type="text" placeholder="Amount to Burn" className="p-2 border rounded" value={burnAmount} onChange={(e) => setBurnAmount(e.target.value)} />
                        <button onClick={handleBurn} disabled={burnStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {burnStatus === 'processing' ? 'Processing...' : 'Burn Tokens'}
                        </button>
                        {burnStatus === 'success' && <div className="text-green-600">Burning successful!</div>}
                        {burnStatus === 'error' && <div className="text-red-600">Burning failed!</div>}
                    </div>
                </div>
                <div className="mb-6">
                    <h2 className="text-xl mb-4">Blacklist Management</h2>
                    <div className="flex flex-col gap-3 mb-4">
                        <input type="text" placeholder="Address to Blacklist" className="p-2 border rounded" value={blacklistAddress} onChange={(e) => setBlacklistAddress(e.target.value)} />
                        <button onClick={handleBlacklist} disabled={blacklistStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {blacklistStatus === 'processing' ? 'Processing...' : 'Add to Blacklist'}
                        </button>
                        {blacklistStatus === 'success' && <div className="text-green-600">Address blacklisted successfully!</div>}
                        {blacklistStatus === 'error' && <div className="text-red-600">Blacklisting failed!</div>}
                    </div>
                    <div className="flex flex-col gap-3">
                        <input type="text" placeholder="Address to Unblacklist" className="p-2 border rounded" value={unblacklistAddress} onChange={(e) => setUnblacklistAddress(e.target.value)} />
                        <button onClick={handleUnblacklist} disabled={unblacklistStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {unblacklistStatus === 'processing' ? 'Processing...' : 'Remove from Blacklist'}
                        </button>
                        {unblacklistStatus === 'success' && <div className="text-green-600">Address unblacklisted successfully!</div>}
                        {unblacklistStatus === 'error' && <div className="text-red-600">Unblacklisting failed!</div>}
                    </div>
                </div>
                <div>
                    <h2 className="text-xl mb-4">Transfer Ownership</h2>
                    <div className="flex flex-col gap-3">
                        <input type="text" placeholder="New Owner Address" className="p-2 border rounded" value={newOwnerAddress} onChange={(e) => setNewOwnerAddress(e.target.value)} />
                        <button onClick={handleTransferOwnership} disabled={transferOwnershipStatus === 'processing'} className="p-2 bg-gray-200 rounded hover:bg-gray-300">
                            {transferOwnershipStatus === 'processing' ? 'Processing...' : 'Transfer Ownership'}
                        </button>
                        {transferOwnershipStatus === 'success' && <div className="text-green-600">Ownership transferred successfully!</div>}
                        {transferOwnershipStatus === 'error' && <div className="text-red-600">Ownership transfer failed!</div>}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default App;