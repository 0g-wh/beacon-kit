package types

import (
	"fmt"

	"github.com/berachain/beacon-kit/primitives/common"
	"github.com/berachain/beacon-kit/primitives/crypto"
	"github.com/berachain/beacon-kit/primitives/eip7685"
	"github.com/berachain/beacon-kit/primitives/math"
	"github.com/karalabe/ssz"
)

const maxWithdrawalRequestsPerPayload = 16
const sszWithdrawRequestSize = 76 // ExecutionAddress = 20, ValidatorPubKey = 48, Amount = 8

// WithdrawalRequest is introduced in EIP7002 which we use for withdrawals.
type WithdrawalRequest struct {
	SourceAddress   common.ExecutionAddress
	ValidatorPubKey crypto.BLSPubkey
	Amount          math.Gwei
}

func (w *WithdrawalRequest) ValidateAfterDecodingSSZ() error {
	return nil
}

// WithdrawalRequests is used for SSZ unmarshalling a list of WithdrawalRequest
type WithdrawalRequests []*WithdrawalRequest

func (w *WithdrawalRequest) DefineSSZ(codec *ssz.Codec) {
	ssz.DefineStaticBytes(codec, &w.SourceAddress)
	ssz.DefineStaticBytes(codec, &w.ValidatorPubKey)
	ssz.DefineUint64(codec, &w.Amount)
}

func (w *WithdrawalRequest) SizeSSZ(_ *ssz.Sizer) uint32 {
	return sszWithdrawRequestSize
}

func (w *WithdrawalRequest) MarshalSSZ() ([]byte, error) {
	buf := make([]byte, ssz.Size(w))
	return buf, ssz.EncodeToBytes(buf, w)
}

// HashTreeRoot returns the hash tree root of the Deposits.
func (w *WithdrawalRequest) HashTreeRoot() common.Root {
	return ssz.HashSequential(w)
}

// MarshalSSZ marshals the WithdrawalRequests object to SSZ format by encoding each deposit individually.
func (wr *WithdrawalRequests) MarshalSSZ() ([]byte, error) {
	return eip7685.MarshalItems[*WithdrawalRequest](*wr)
}

// DecodeWithdrawalRequests decodes SSZ data by decoding each withdrawal individually.
func DecodeWithdrawalRequests(data []byte) (WithdrawalRequests, error) {
	maxSize := maxWithdrawalRequestsPerPayload * sszWithdrawRequestSize
	if len(data) > maxSize {
		return nil, fmt.Errorf(
			"invalid withdrawal requests SSZ size, requests should not be more "+
				"than the max per payload, got %d max %d", len(data), maxSize,
		)
	}
	withdrawalSize := int(ssz.Size(&WithdrawalRequest{}))
	if len(data) < withdrawalSize {
		return nil, fmt.Errorf("invalid withdrawal requests SSZ size, got %d expected at least %d", len(data), withdrawalSize)
	}
	// Use the generic unmarshalItems helper.
	items, err := eip7685.UnmarshalItems[*WithdrawalRequest](
		data,
		withdrawalSize,
		func() *WithdrawalRequest { return new(WithdrawalRequest) },
	)
	if err != nil {
		return nil, err
	}
	withdrawals := WithdrawalRequests(items)
	return withdrawals, nil
}
